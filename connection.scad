// Connection bump / groove modules
// Bump is the smaller protrusion, groove is the larger channel that receives it.

module connection_sweep(diameter) {
  scale([1, 1, get_connection_height_scale()])
    path_sweep2d(
      circle(d = diameter),
      rect([get_x_width_outside() - thickness, get_y_depth_outside() - thickness],
          rounding = get_connection_rounding()),
      closed=true
    );
}

// type = "bump" or "groove"
module connection_box(type) {
  if (get_generate_connection()) {
    assert(connection_groove_percentage >= connection_bump_percentage,
      str("connection_groove_percentage must be greater than or equal to connection_bump_percentage. ",
          "Groove: ", connection_groove_percentage, "%, Bump: ", connection_bump_percentage, "%"));
  }

  should_render = get_generate_connection() && (
    (type == "bump" && connection_type == "bump_box") ||
    (type == "groove" && connection_type == "bump_lid")
  );

  if (should_render) {
    left(get_generate_lid() ? get_x_width_outside()/2 + get_box_x_margin() : 0)
    up(get_bottom_height_outside())
      connection_sweep(type == "bump" ? get_connection_bump_diameter() : get_connection_groove_diameter());
  }
}

// type = "bump" or "groove"
module connection_lid(type) {
  should_render = get_generate_connection() && (
    (type == "bump" && connection_type == "bump_lid") ||
    (type == "groove" && connection_type == "bump_box")
  );

  if (should_render) {
    move([get_x_width_outside()/2 + get_lid_x_margin(), 0, get_lid_height_outside()])
      connection_sweep(
        type == "bump"
          ? get_connection_bump_diameter()
          : get_connection_groove_diameter()
      );
  }
}
