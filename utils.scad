// XOR
function xor(a, b) = a != b;

// Model detail
function get_model_detail() = $preview ? model_detail_preview : model_detail_stl;

// Cosine polygon
function get_cosine_polygon_x_size(periods, y_size, x_scale) =
  periods * PI * y_size * x_scale;
module cosine_polygon(y_size, periods, x_scale = 1, is_negative = false) {
  steps = 100 * periods * get_model_detail();
  degrees = periods * 360;
  x_size = get_cosine_polygon_x_size(periods, y_size, x_scale);
  y_aplitude = y_size / 2;
  cosine_polygon_points = [
      for (i = [0:steps])
        let(x = i * x_size / steps, degree = i * degrees / steps)
          [x, cos(degree) * y_aplitude],
      [x_size, -y_aplitude],
      [0, -y_aplitude]
  ];
  if (is_negative) {
    difference() {
      rect([x_size, y_size], anchor=LEFT);
      offset(SWO)
        polygon(cosine_polygon_points);
    }
  } else {
    offset(SWO)
      polygon(cosine_polygon_points);
  }
}

// Compartments
function get_compartments_grid() = parse_compartments_grid(compartments_dimensions);
function parse_compartments_grid(spec) =
  let(
    rows_raw = str_split(spec, ";"),
    rows = [for (r = rows_raw)
              [for (tok = str_split(r, ","))
                 let(c = str_strip(tok, " \t"))
                 if (c != "") parse_num(c)]],
    all_values = [for (row = rows) for (v = row) v],
    bad_values = [for (v = all_values) if (!is_num(v) || v != v || v <= 0) v],
    a1 = assert(len([for (row = rows) if (len(row) == 0) row]) == 0,
           str("compartments_dimensions must not have empty rows (check for leading, trailing or double ';'). ",
               "Input: ", spec)),
    a2 = assert(len(bad_values) == 0,
           str("compartments_dimensions must only contain positive, parseable numbers. ",
               "Input: ", spec)),
    a3 = assert(len([for (row = rows) if (len(row) < 2) row]) == 0,
           str("Each row must have at least 2 values (depth and at least one width). ",
               "Rows: ", rows))
  )
  [for (row = rows) [row[0], [for (i = [1:len(row)-1]) row[i]]]];

// Derived flags
function get_generate_lid() = lid_type != "no_lid";
function get_generate_lip() = (
  lid_type == "lip" || lid_type == "lip_magnets" || lid_type == "lip_latches"
);
function get_generate_magnets() = (
  lid_type == "magnets" || lid_type == "lip_magnets" || lid_type == "hinges_magnets"
);
function get_generate_hinges() = (
  lid_type == "hinges" || lid_type == "hinges_magnets" || lid_type == "hinges_latches"
);
function get_generate_latches() = (
  lid_type == "latches" || lid_type == "lip_latches" || lid_type == "hinges_latches"
);
function get_generate_latches_back() = (lid_type == "latches" || lid_type == "lip_latches");
function get_generate_connection() = (
  connection_type != "off" &&
  get_generate_lid() && lid_type != "slider" &&
  !get_generate_lip() &&
  connection_groove_percentage > 0 && connection_bump_percentage > 0
);

// Lip
function get_lp_height() = get_generate_lip() ? lip_height : 0;
function get_lp_thickness() = get_generate_lip() ? lip_thickness : 0;
function get_lp_tolerance() = get_generate_lip() ? lip_tolerance : 0;

// Final margins
function get_box_x_margin() = 2;
function get_lid_x_margin() = 2;
function get_latch_margin() = 2;

// Dimensions
function get_rows_size() = sum([for (row = get_compartments_grid()) row[0]])
             + (len(get_compartments_grid()) - 1) * separator_thickness;
function get_columns_size() = max([for (row = get_compartments_grid())
  let(widths = row[1], n = len(widths))
  sum(widths) + (n - 1) * separator_thickness
]);
function get_x_width() = compartments_transpose ? get_rows_size() : get_columns_size();
function get_y_depth() = compartments_transpose ? get_columns_size() : get_rows_size();
function get_x_width_outside() = get_x_width() +
                                 thickness*2 +
                                 get_lp_thickness()*2 +
                                 get_lp_tolerance()*2;
function get_y_depth_outside() = get_y_depth() +
                                 thickness*2 +
                                 get_lp_thickness()*2 +
                                 get_lp_tolerance()*2;
function get_bottom_height_outside() = bottom_height + thickness;
function get_box_height_inside() = bottom_height + get_lp_height();
function get_box_height_outside() = get_bottom_height_outside() + get_lp_height();
function get_lid_height_outside() = lid_type == "slider" ? slider_lid_thickness : lid_height + thickness;
function get_lip_rounding() = max(
  MIN_CORNER_RADIUS,
  corner_outer_radius - thickness - get_lp_tolerance()
);
function get_lid_cut_out_rounding() = max(MIN_CORNER_RADIUS, corner_outer_radius - thickness);

// Hinges
function get_hinge_knuckle_offset() = hinge_knuckle_diameter / 2 + hinge_mount_gap;
function get_hinge_length() = hinge_join_type == "screw_self_tap"
  ? hinge_self_tap_screw_length + hinge_self_tap_screw_gap
  : hinge_join_type == "screw_nut"
    ? hinge_screw_length + hinge_screw_head_width + 4*hinge_hardware_tolerance
    : hinge_join_type == "snap_fit"
      ? hinge_snap_fit_length
      : hinge_pin_length;
function get_hinge_hole_diameter() = hinge_join_type == "screw_self_tap"
  ? hinge_self_tap_screw_type
  : hinge_join_type == "screw_nut"
    ? hinge_screw_diameter
    : hinge_join_type == "snap_fit"
      ? get_in_place_knuckle_hinge_pin_diam(hinge_knuckle_diameter)
      : hinge_pin_diameter;
function get_in_place_knuckle_hinge_pin_diam(knuckle_diam) =
  knuckle_diam >= 5
    ? knuckle_diam - 1
    : knuckle_diam * 0.8;

// Magnets
function get_magnet_holder_radius() = magnet_holder_diameter/2;
function get_magnet_holder_rounding_fix_offset() = max(
  0,
  ((sqrt(2) - 1) * (get_lip_rounding() - get_magnet_holder_radius())) / sqrt(2)
);
function get_magnet_hole_diameter() = magnet_diameter + 2*magnet_tolerance;
function get_magnet_hole_height() = magnet_height + magnet_glue_height + 2*magnet_tolerance;

// Connection groove / bump
function get_connection_groove_diameter() = connection_groove_percentage / 100 * thickness;
function get_connection_bump_diameter() = connection_bump_percentage / 100 * thickness;
function get_connection_rounding() = max(MIN_CORNER_RADIUS, corner_outer_radius - thickness/2);

// Latches
function get_latch_slope() = 6;
function get_latch_radius() = min(latch_x_width, latch_z_height) / 10;
function get_latch_x_width_outside() = latch_x_width * 1.5;
function get_latch_x_width_back() = latch_x_width * 0.9;
function get_latch_hinge_diameter() = latch_y_thickness;
function get_latch_inner_hinge_segment_width() = latch_x_width
                                                 - latch_z_height / get_latch_slope() * 2
                                                 + latch_hinge_segments_gap;
function get_latch_notch_y_depth() = latch_y_thickness / 2;
function get_latch_notch_z_height() = min(latch_y_thickness / 2, latch_z_height / 5);
function get_latch_snap_lock_diameter_female() = 3;
function get_latch_snap_lock_diameter_male() = get_latch_snap_lock_diameter_female() * 0.9;
function get_latch_support_z_height() = latch_y_thickness * tan(90 - latch_support_angle);

// Slider lid
function get_slider_lid_snap_lock_x_scale() = 3;
function get_slider_lid_grip() = slider_lid_rail_grip / 100 * thickness;
function get_slider_lid_snap_lock_size() = min(
  0.15
    + 0.1 * get_y_depth() / 100
    + 0.3 * slider_lid_snap_lock_firmness,
  get_slider_lid_grip()
);
function get_slider_rail_base_cut_x(is_lid_part) =
  get_x_width_outside()
  - max(thickness, corner_outer_radius)
  - (is_lid_part ? 0 : slider_lid_tolerance);
function get_slider_lid_notches_width() =
  slider_lid_notches_number * slider_lid_notch_width
  + (slider_lid_notches_number - 1) * slider_lid_notches_spacing;

// Lid notches
function get_lid_notch_radius() = thickness / 2;
