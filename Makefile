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

.PHONY: clean
clean:
	rm -f boxee.scad boxee-customizer.scad boxee.stl main.stl
