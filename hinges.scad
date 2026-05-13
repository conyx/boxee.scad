module hinge(is_box_hinge) {
  screw_head_cut_h = hinge_screw_head_width + 2*hinge_hardware_tolerance;
  screw_head_cut_d = hinge_screw_head_diameter + 2*hinge_hardware_tolerance;
  screw_nut_cut_h = hinge_nut_width + 2*hinge_hardware_tolerance;
  screw_nut_cut_id = hinge_nut_size + 2*hinge_hardware_tolerance;

  color(OUTSIDE_ACCESSORIES_COLOR)
  difference() {
    knuckle_hinge(length = get_hinge_length(),
                  segs = hinge_segments,
                  offset = get_hinge_knuckle_offset(),
                  knuckle_diam = hinge_knuckle_diameter,
                  pin_diam = get_hinge_hole_diameter(),
                  screw_head = "flat",
                  tap_depth = hinge_self_tap_screw_tap_depth,
                  in_place = hinge_join_type == "print_in_place",
                  gap = hinge_segments_gap,
                  inner = !is_box_hinge,
                  arm_angle = hinge_arm_angle,
                  clear_top = true,
                  seg_ratio = hinge_segments_ratio,
                  orient = BACK,
                  spin = 180,
                  $slop = hinge_join_type != "print_in_place" ? hinge_hardware_tolerance : 0);

    // Screw head/nut hole in first segment
    if (hinge_join_type == "screw_nut") {
      x_offset = get_hinge_length()/2 - screw_head_cut_h/2 + SWO/2;
      y_offset = hinge_knuckle_diameter/2 + hinge_mount_gap;
      odd_segments = hinge_segments % 2 == 1;

        if (xor(!is_box_hinge, odd_segments)) {
          move([x_offset * (is_box_hinge ? -1 : 1), y_offset, 0])
            regular_prism(
              6,
              h = screw_nut_cut_h + SWO,
              id = screw_nut_cut_id,
              orient = RIGHT
            );
        }

        if (is_box_hinge) {
          move([x_offset, y_offset, 0])
          xcyl(h = screw_head_cut_h + SWO,
               d = screw_head_cut_d);
        }
    }
  }
}

module hinges() {
  // Hinge-related assertions (only when hinges are used)
  if (get_generate_hinges()) {
    assert(hinges_number * get_hinge_length() <= get_x_width_outside(),
           str("Total hinge length exceeds box width. ",
               "Total hinge length: ", hinges_number * get_hinge_length(), "mm, ",
               "box width: ", get_x_width_outside(), "mm"));

    if (hinge_join_type == "print_in_place") {
      assert(hinge_segments >= 3,
             str("Print-in-place hinge requires at least 3 segments. ",
                 "Current segments: ", hinge_segments));
    }

    if (hinge_join_type == "screw_nut") {
      screw_head_cut_diameter = hinge_screw_head_diameter + 2*hinge_hardware_tolerance;
      screw_nut_cut_diameter = (hinge_nut_size + 2*hinge_hardware_tolerance) / cos(30);

      assert(hinge_knuckle_diameter >= screw_head_cut_diameter,
             str("hinge_knuckle_diameter is too small for screw head. ",
                 "Knuckle diameter: ", hinge_knuckle_diameter, "mm, ",
                 "screw head diameter (with tolerance): ", screw_head_cut_diameter, "mm"));

      assert(hinge_knuckle_diameter >= screw_nut_cut_diameter,
             str("hinge_knuckle_diameter is too small for screw nut. ",
                 "Knuckle diameter: ", hinge_knuckle_diameter, "mm, ",
                 "nut outer diameter (with tolerance): ", screw_nut_cut_diameter, "mm"));
    }
  }

  if (get_generate_hinges()) {
    // Calculate spacing for equal distribution along X axis
    hinge_spacing = (get_x_width_outside() - hinges_number * get_hinge_length()) / (hinges_number + 1);

    box_center_x = -(get_x_width_outside()/2 + get_box_x_margin());
    lid_center_x = get_x_width_outside()/2 + get_lid_x_margin();
    hinge_y = get_y_depth_outside()/2;

    for (i = [0 : hinges_number - 1]) {
      hinge_x_offset = (i + 1) * hinge_spacing + (i + 0.5) * get_hinge_length() - get_x_width_outside()/2;

      // Box hinge at top of box
      move([box_center_x + hinge_x_offset, hinge_y, get_box_height_outside()])
      mirror([hinge_flip_last && i == 0 ? 1 : 0, 0, 0])
        hinge(is_box_hinge = true);

      // Lid hinge at top of lid
      move([lid_center_x + hinge_x_offset, hinge_y, get_lid_height_outside()])
      mirror([hinge_flip_last && i == hinges_number - 1 ? 1 : 0, 0, 0])
        hinge(is_box_hinge = false);
    }
  }
}
