module slider_lid_base(is_clearance = false) {
  h = slider_lid_thickness + (is_clearance ? SWO * 2 : 0);
  cuboid([get_x_width(), get_y_depth(), h],
         rounding = get_lid_cut_out_rounding(),
         edges = "Z");
}

module slider_rail_base_part_rounding_mask(is_lid_part) {
  slider_rail_base_part_rounding = min(
    slider_lid_thickness,
    max(corner_outer_radius, thickness)
  ) / 2;
  up(slider_lid_thickness / 2)
    right(
      get_x_width_outside() / 2
      - (get_x_width_outside() - get_slider_rail_base_cut_x(is_lid_part))
      + (is_lid_part ? -1 : 1) * SWO
    )
      difference() {
        rounding_edge_mask(
          height=get_y_depth_outside() + SWO,
          r=slider_rail_base_part_rounding,
          excess=SWO,
          spin=is_lid_part ? 270 : 90,
          orient=is_lid_part ? FRONT : BACK
        );
        if (is_lid_part) {
          cuboid([
            slider_rail_base_part_rounding * 4,
            get_y_depth(),
            slider_lid_thickness * 2
          ]);
        }
      }
}

module slider_rail_base_part_mask(is_lid_part) {
  mask_x_width = get_slider_rail_base_cut_x(is_lid_part) + SWO * 2;
  mask_y_depth = get_y_depth_outside() + SWO * 2;
  mask_z_height = slider_lid_thickness + SWO * 2;

  left((get_x_width_outside() - mask_x_width) / 2 + SWO)
    cuboid([
      mask_x_width,
      mask_y_depth,
      mask_z_height
    ]);
}

module slider_rail_base_part(is_lid_part) {
  if (is_lid_part) {
    difference() {
      slider_rail_base();
      slider_rail_base_part_mask(is_lid_part);
      slider_rail_base_part_rounding_mask(is_lid_part);
    }
  } else {
    difference() {
      intersection() {
        slider_rail_base_part_mask(is_lid_part);
        slider_rail_base();
      }
      slider_rail_base_part_rounding_mask(is_lid_part);
    }
  }
}

module slider_rail_base() {
  difference() {
      cuboid([get_x_width_outside(), get_y_depth_outside(), slider_lid_thickness],
             rounding = corner_outer_radius,
             edges = "Z");
      slider_lid_base(is_clearance = true);
    }
}

module slider_base(is_clearance = false) {
  grip = get_slider_lid_grip();
  h = slider_lid_thickness + (is_clearance ? SWO * 2 : 0);
  profile = [
    [0, 0],
    [grip, 0],
    [0, h]
  ];
  profile_clearance = [
    [-SWO, 0],
    [slider_lid_tolerance + grip, 0],
    [slider_lid_tolerance, h],
    [-SWO, h]
  ];
  path = rect([get_x_width(), get_y_depth()], rounding = get_lid_cut_out_rounding());
  down(h/2)
    path_sweep2d(is_clearance ? profile_clearance : profile, path, closed = true);
}

module slider_rail_snap_lock_front_base_2d(snap_lock_male_size) {
  cosine_wave(
    y_size=snap_lock_male_size,
    periods=1,
    x_scale=get_slider_lid_snap_lock_x_scale(),
    is_negative=true
  );
}

module slider_rail_snap_lock_front() {
  if (slider_lid_snap_lock) {
    grip = get_slider_lid_grip();
    snap_lock_female_size = get_slider_lid_snap_lock_size();
    snap_lock_female_period_x_size = get_cosine_wave_x_size(
      1,
      snap_lock_female_size,
      get_slider_lid_snap_lock_x_scale()
    );
    snap_lock_male_size = snap_lock_female_size * 0.9;
    snap_lock_male_period_x_size = get_cosine_wave_x_size(
      1,
      snap_lock_male_size,
      get_slider_lid_snap_lock_x_scale()
    );
    move([
      - get_x_width() / 2
        + get_lid_cut_out_rounding()
        + snap_lock_female_period_x_size / 2
        + (snap_lock_female_period_x_size - snap_lock_male_period_x_size) / 2,
      - get_y_depth() / 2 - grip + snap_lock_female_size / 2,
      - slider_lid_thickness / 2
    ]) {
      yflip()
      linear_extrude(slider_lid_thickness)
        hull() {
          back(slider_lid_tolerance)
            slider_rail_snap_lock_front_base_2d(snap_lock_male_size);
          slider_rail_snap_lock_front_base_2d(snap_lock_male_size);
        }
    }
  }
}

module slider_rail_snap_lock_back() {
  yflip() slider_rail_snap_lock_front();
}

module slider_rail_snap_lock() {
  union() {
    slider_rail_snap_lock_front();
    slider_rail_snap_lock_back();
  }
}

module slider_base_snap_lock_clearance_front() {
  if (slider_lid_snap_lock) {
    grip = get_slider_lid_grip();
    snap_lock_size = get_slider_lid_snap_lock_size();
    clearance_height = slider_lid_thickness * 2;
    move([
      - get_x_width() / 2 + get_lid_cut_out_rounding() - SWO,
      - get_y_depth() / 2 - grip + snap_lock_size / 2 - SWO,
      - slider_lid_thickness
    ]) {
      right(SWO)
        cuboid(
          [max(grip, get_lid_cut_out_rounding()) * 2,
           snap_lock_size,
           clearance_height],
          anchor=RIGHT+BOTTOM
        );
      linear_extrude(clearance_height)
        cosine_wave(
          y_size=snap_lock_size,
          periods=1.5,
          x_scale=get_slider_lid_snap_lock_x_scale()
        );
    }
  }
}

module slider_base_snap_lock_clearance_back() {
  yflip() slider_base_snap_lock_clearance_front();
}

module slider_base_snap_lock_clearance() {
  union() {
    slider_base_snap_lock_clearance_front();
    slider_base_snap_lock_clearance_back();
  }
}

module slider_lid_notch() {
  wedge([get_y_depth() + 2 * SWO,
       slider_lid_thickness * slider_lid_notch_height / 100,
       slider_lid_notch_width],
      center = true,
      spin = 90,
      orient = LEFT);
}

module slider_lid_notches_clearance_base() {
  step = slider_lid_notch_width + slider_lid_notches_spacing;
  up(slider_lid_thickness * (1 - slider_lid_notch_height / 100) / 2 + SWO)
    xcopies(spacing = step, n = slider_lid_notches_number)
      slider_lid_notch();
}

module slider_lid_notches_clearance_shape() {
  w = get_slider_lid_notches_width();
  linear_extrude(2 * slider_lid_thickness, center = true)
  rotate(slider_lid_notches_shape_flip ? 180 : 0) {
    if (slider_lid_notches == "full") {
      square([w, get_y_depth() + 2 * SWO], center = true);
    } else if (slider_lid_notches == "circle") {
      circle(d = w);
    } else if (slider_lid_notches == "triangle") {
      ngon_side = (2 * w) / sqrt(3);
      ngon_rounding = w/12;
      left(w / 6 - ngon_rounding / 2)
        offset(ngon_rounding / 2)
          regular_ngon(n = 3, side = ngon_side, rounding = ngon_rounding);
    } else if (slider_lid_notches == "square") {
      rect([w, w], rounding = w/10);
    } else if (slider_lid_notches == "hexagon") {
      hexagon(r = w / (2 * sin(60)), rounding = w/12, spin = 90);
    } else if (slider_lid_notches == "teardrop") {
      td_ang = 30;
      // tip reaches r/sin(ang) = 2r, total span = 3r = w
      td_r = w / 3;
      // center bounding box: tip extends r further than circle
      right(td_r / 2)
        teardrop2d(r = td_r, ang = td_ang, spin = 90);
    } else if (slider_lid_notches == "cross") {
      arm = w / 3;
      union() {
        rect([w, arm], rounding = arm/4);
        rect([arm, w], rounding = arm/4);
      }
    } else if (slider_lid_notches == "heart") {
      r = w / 4;
      tiny_r = w / 40;
      union() {
        hull() {
          translate([-r, r]) circle(r = r);
          translate([w/2 - tiny_r, 0]) circle(r = tiny_r);
        }
        hull() {
          translate([-r, -r]) circle(r = r);
          translate([w/2 - tiny_r, 0]) circle(r = tiny_r);
        }
      }
    }
  }
}

module slider_lid_notches_clearance() {
  if (slider_lid_notches != "none") {
    right(get_x_width()/2 - get_slider_lid_notches_width()/2 - slider_lid_notches_right_offset)
      intersection() {
        slider_lid_notches_clearance_base();
        slider_lid_notches_clearance_shape();
      }
  }
}

module slider_lid() {
  move([get_x_width_outside()/2 + get_lid_x_margin(), 0, slider_lid_thickness/2]) {
    difference() {
      slider_lid_base();
      slider_lid_notches_clearance();
    }
    slider_rail_base_part(is_lid_part = true);
    difference() {
      slider_base();
      slider_base_snap_lock_clearance();
    }
  }
}

module slider_rail_box() {
  left(get_x_width_outside()/2 + get_box_x_margin())
  up(get_bottom_height_outside() + slider_lid_thickness/2) {
    difference() {
      slider_rail_base_part(is_lid_part = false);
      slider_base(is_clearance = true);
    }
    slider_rail_snap_lock();
  }
}
