module latch_dovetail(is_male) {
  dovetail(is_male? "male" : "female",
           slide=latch_y_thickness,
           width=latch_x_width,
           back_width=get_latch_x_width_back(),
           height=latch_z_height,
           radius=get_latch_radius(),
           slope = get_latch_slope(),
           extra = is_male ? 0 : TINY,
           $slop=latch_tolerance);
}

module latch_hinge(is_male) {
  rot(a = is_male ? 180 : 90, v = is_male ? BACK : RIGHT)
    knuckle_hinge_wrapper(
      length = get_latch_x_width_outside(),
      segs = 3,
      offset = get_latch_hinge_diameter() / 2,
      knuckle_diam = get_latch_hinge_diameter(),
      gap = latch_hinge_segments_gap,
      inner = is_male,
      snap_fit=true,
      snap_fit_firmness = latch_hinge_firmness,
      pin_diam = get_in_place_knuckle_hinge_pin_diam(get_latch_hinge_diameter()),
      arm_angle = is_male ? 90 : latch_hinge_arm_angle,
      seg_ratio = get_latch_inner_hinge_segment_width() /
                  ((get_latch_x_width_outside() - get_latch_inner_hinge_segment_width()) / 2)
    );
}

module latch_female_support() {
  latch_x_width_female = latch_x_width + latch_tolerance * 2;
  latch_x_width_back_female = get_latch_x_width_back() + latch_tolerance * 2;
  top_mount = [[0, 0],
               [0, latch_y_thickness],
               [(get_latch_x_width_outside() - latch_x_width_back_female) / 2, latch_y_thickness],
               [(get_latch_x_width_outside() - latch_x_width_female) / 2, 0]];
  bottom_mount = [[0, latch_y_thickness - TINY],
                  [0, latch_y_thickness],
                  [(get_latch_x_width_outside() - latch_x_width_female) / 2, latch_y_thickness],
                  [(get_latch_x_width_outside() - latch_x_width_female) / 2, latch_y_thickness - TINY]];
  skin([bottom_mount, top_mount], z=[0,get_latch_support_z_height()], slices=$fn);
}

module latch_female_support_left() {
  move([-get_latch_x_width_outside() / 2,
        -latch_y_thickness / 2,
        -get_latch_support_z_height() - latch_z_height / 2])
    latch_female_support();
}

module latch_female_support_right() {
  xflip() latch_female_support_left();
}

module latch_female_supports() {
  latch_female_support_left();
  latch_female_support_right();
}

module latch_notch() {
  move([0, get_latch_notch_y_depth() / 2, latch_z_height - get_latch_notch_z_height() / 2])
        cuboid([latch_x_width,
                get_latch_notch_y_depth() + TINY,
                get_latch_notch_z_height() + TINY]);
}

module latch_snap_lock(is_male) {
  diameter = is_male ? get_latch_snap_lock_diameter_male() : get_latch_snap_lock_diameter_female();
  sphere(d = diameter);
}

module latch_snap_lock_right(is_male) {
  diameter = is_male ? get_latch_snap_lock_diameter_male() : get_latch_snap_lock_diameter_female();
  z_offset = get_latch_notch_z_height() + get_latch_snap_lock_diameter_female() / 2;
  x_offset = z_offset / get_latch_slope() + (diameter / 2) * (0.7 - 0.2 * latch_snap_lock_firmness);
  move([mean([latch_x_width, get_latch_x_width_back()]) / 2 - x_offset,
        0,
        latch_z_height - z_offset])
    latch_snap_lock(is_male);
}

module latch_snap_lock_left(is_male) {
  xflip() latch_snap_lock_right(is_male);
}

module latch_snap_locks(is_male) {
  latch_snap_lock_left(is_male);
  latch_snap_lock_right(is_male);
}

module latch_lid_hinge() {
   latch_hinge(false);
}

module latch_lid() {
  xrot(90) union() {
    difference() {
      latch_dovetail(true);
      latch_notch();
    }
    if (latch_snap_lock) {
      latch_snap_locks(true);
    }
    latch_hinge(true);
  }
}

module latch_box() {
  up(latch_z_height) xrot(180) {
    difference() {
      up(latch_z_height / 2) xrot(180) {
        xrot(-90)
          diff("female_dovetail")
            cuboid([get_latch_x_width_outside(), latch_z_height, latch_y_thickness]) {
              tag("female_dovetail")
                attach(FRONT)
                  latch_dovetail(false);
          }
        latch_female_supports();
      }
      if (latch_snap_lock) {
        latch_snap_locks(false);
      }
    }
  }
}

module latches_front() {
  // Calculate spacing for equal distribution along X axis
  latch_spacing = (get_x_width_outside() - latches_number * get_latch_x_width_outside())
                  / (latches_number + 1);

  box_center_x = -(get_x_width_outside()/2 + get_box_x_margin());
  lid_center_x = get_x_width_outside()/2 + get_latch_margin();
  latch_y = -get_y_depth_outside()/2;

  color(OUTSIDE_ACCESSORIES_COLOR)
    for (i = [0 : latches_number - 1]) {
      latch_x_offset = (i + 1) * latch_spacing
                       + (i + 0.5) * get_latch_x_width_outside()
                       - get_x_width_outside()/2;

      // Latch box on front-top of box (Z offset by hinge diameter)
      move([box_center_x + latch_x_offset,
            latch_y - latch_y_thickness/2,
            get_bottom_height_outside() - latch_z_height - get_latch_hinge_diameter()/2])
        latch_box();

      // Latch lid hinge on front-top of lid
      move([lid_center_x + latch_x_offset,
            latch_y,
            get_lid_height_outside()])
        latch_lid_hinge();

      // Separate latch lid parts next to the lid (right of lid)
      move([get_x_width_outside()
              + get_latch_margin()
              + get_latch_margin()
              + latch_x_width/2
              + i * (latch_x_width + get_latch_margin()),
            -latch_y_thickness - get_latch_margin(),
            latch_y_thickness / 2])
        latch_lid();
    }
}

module latches_back() {
  yflip() latches_front();
}

module latches() {
  if (get_generate_latches()) {
    assert(latches_number * get_latch_x_width_outside() <= get_x_width_outside(),
           str("Total latch width exceeds box width. ",
               "Total latch width: ", latches_number * get_latch_x_width_outside(), "mm, ",
               "box width: ", get_x_width_outside(), "mm"));

    latches_front();
    if (get_generate_latches_back()) {
      latches_back();
    }
  }
}
