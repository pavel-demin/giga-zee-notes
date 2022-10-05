IMAGES = $(patsubst %.svg,%.pdf,$(wildcard images/*.svg))

.PRECIOUS: $(IMAGES)

all: development_documentation.pdf

%.pdf: %.tex $(IMAGES)
	xelatex $(basename $<)
	biber $(basename $<)
	xelatex $(basename $<)

images/%.pdf: images/%.svg
	inkscape --export-type=pdf $<

clean:
	rm -f $(IMAGES)
	rm -f *.aux *.log *.pdf
	rm -f *.bbl *.bcf *.blg *.out *.run.xml *.toc
