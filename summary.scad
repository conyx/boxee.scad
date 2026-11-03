// Output final outside dimensions and needed accessories as 3D text
module summary() {
  // Column 1: Outside dimensions
  col1 = concat(
    ["Outside dimensions:",
     str("X (width): ", get_x_width_outside(), "mm"),
     str("Y (depth): ", get_y_depth_outside(), "mm")],
    get_generate_hinges() || get_generate_latches()
      ? [str("Y (depth) w/ hinges",
             ": ",
             get_y_depth_outside()
               + (get_generate_hinges() ? (hinge_mount_gap + hinge_knuckle_diameter) : 0)
               + (get_generate_latches() ? get_latch_hinge_diameter() : 0)
               + (get_generate_latches_back() ? get_latch_hinge_diameter() : 0),
             "mm")]
      : [],
    [str(lid_type == "slider"
           ? "Z (height) box (incl. slider rail): "
           : get_generate_lip()
             ? "Z (height) box (incl. lip): "
             : "Z (height) box: ",
         get_box_height_outside() + (lid_type == "slider" ? slider_lid_thickness : 0),
         "mm")],
    get_generate_lid()
      ? [str("Z (height) lid: ", get_lid_height_outside(), "mm"),
         // The lip sits inside the lid, so it doesn't add to the overall height
         str("Z (height) overall: ", get_bottom_height_outside() + get_lid_height_outside(), "mm")]
      : []
  );

  // Column 2: Magnets
  col2 = get_generate_magnets()
    ? ["Magnets:",
       str("Count: ", magnets_number),
       str("Diameter: ", magnet_diameter, "mm"),
       str("Height: ", magnet_height, "mm")]
    : [];

  // Column 3: Hinges
  col3 = get_generate_hinges() && hinge_join_type != "snap_fit"
    ? concat(
        ["Hinges:"],
        hinge_join_type == "screw_nut"
          ? [str("Screws and nuts count: ", hinges_number),
             str("Screw length (w/o head): ", hinge_screw_length, "mm"),
             str("Screw diameter: ", hinge_screw_diameter, "mm"),
             str("Screw head width: ", hinge_screw_head_width, "mm"),
             str("Screw head diameter: ", hinge_screw_head_diameter, "mm"),
             str("Nut width: ", hinge_nut_width, "mm"),
             str("Nut size: ", hinge_nut_size, "mm")]
          : hinge_join_type == "screw_self_tap"
            ? [str("Self-tapping screws needed: ", hinges_number),
               str("Screw type (diameter): ", hinge_self_tap_screw_type),
               str("Screw length (incl. head): ", hinge_self_tap_screw_length, "mm")]
            : [str("Pins needed: ", hinges_number),
               str("Diameter: ", hinge_pin_diameter, "mm"),
               str("Length: ", get_hinge_length(), "mm")])
    : [];

  // Column 4: Printing pause (magnet closure)
  box_pause = get_box_height_outside() - magnet_closure_height;
  lid_pause = get_lid_height_outside() - get_lp_height() - magnet_closure_height;
  col4 = (get_generate_magnets() && magnet_generate_closure)
    ? ["Pause printing to insert magnets:",
       str("Box: AFTER Z layer: <", box_pause, ">mm"),
       str("Lid: AFTER Z layer: <", lid_pause, ">mm")]
    : [];

  // Echo summary
  all_lines = concat(col1, col2, col3, col4);
  for (i = [0:max(0, len(all_lines) - 1)]) echo(all_lines[i]);

  // Summary plate
  if (generate_summary_plate && $preview) {
    padding = get_x_width_outside() / 40;
    text_plate_width = max(
      (get_generate_lid()
        ? 2 * get_x_width_outside() + get_box_x_margin() + get_lid_x_margin()
        : get_x_width_outside()) - 2 * padding,
      get_y_depth_outside()
    );
    font_size = (1 / 80) * text_plate_width;
    line_height = font_size * 1.5;

    // Box left edge X position
    text_x = - text_plate_width / 2;

    // 15 units in front of the box (-Y direction)
    text_y = -(get_y_depth_outside() / 2) - 15;

    // Columns X positions
    col1_x = text_x;
    col2_x = col1_x + font_size * 23;
    col3_x = col2_x + ((len(col2) > 0) ? font_size * 13 : 0);
    col4_x = col3_x + ((len(col3) > 0) ? font_size * 23 : 0);

    // Render columns [lines, x_position]
    columns = [[col1, col1_x], [col2, col2_x], [col3, col3_x], [col4, col4_x]];

    for (c = [0:len(columns) - 1])
      if (len(columns[c][0]) > 0)
        for (i = [0:len(columns[c][0]) - 1])
          summary_line(columns[c][0][i], columns[c][1], text_y, i, font_size, line_height);

    // Background rectangle
    max_lines = max([for (c = columns) len(c[0])]);
    bg_width = text_plate_width + 2 * padding;
    bg_height = font_size + 2 * padding + (max_lines - 1) * line_height;

    color(INSIDE_ACCESSORIES_COLOR)
      linear_extrude(1)
        translate([text_x - padding + bg_width / 2,
                   text_y - (max_lines - 1) * line_height - padding + bg_height / 2])
          rect([bg_width, bg_height], rounding = padding / 2);
  }
}

module summary_line(txt, x, y, line, font_size, line_height) {
  color(OUTSIDE_ACCESSORIES_COLOR)
    linear_extrude(1.2)
      translate([x, y - line * line_height])
        text(str(line == 0 ? "" : "- ", txt),
             size = font_size,
             font = "Liberation Sans");
}
