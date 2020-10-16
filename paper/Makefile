# type "make" command in Unix to create entropy-debugging.pdf file 
all:
	latex entropy-debugging
	bibtex entropy-debugging
	latex entropy-debugging
	latex entropy-debugging
	dvips -o entropy-debugging.ps entropy-debugging
	ps2pdf entropy-debugging.ps entropy-debugging.pdf

clean:
	(rm -rf *.ps *.log *.dvi *.aux *.*% *.lof *.lop *.lot *.toc *.idx *.ilg *.ind *.bbl *blg)
