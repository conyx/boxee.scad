.PHONY: unify
unify: boxee.scad
boxee.scad: main.scad unify.py
	@python3 unify.py $< > $@
	@echo "Generated $@"

.PHONY: customizer
customizer: boxee-customizer.scad
boxee-customizer.scad: main.scad unify.py
	@python3 unify.py --remove-preview $< > $@
	@echo "Generated $@"

BOSL2_DIR := $(HOME)/.local/share/OpenSCAD/libraries/BOSL2

.PHONY: pack
pack: boxee.zip
boxee.zip: boxee.scad
	@rm -rf boxee $@
	@mkdir -p boxee/BOSL2
	@cp boxee.scad boxee/
	@cp $(BOSL2_DIR)/*.scad $(BOSL2_DIR)/LICENSE boxee/BOSL2/
	@zip -qr $@ boxee
	@rm -rf boxee
	@echo "Generated $@"

.PHONY: clean
clean:
	rm -f boxee.scad boxee-customizer.scad *.stl boxee.zip
