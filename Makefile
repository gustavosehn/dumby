build:
	if not exist build mkdir build
	py -m nuitka --onefile --output-dir=build dumby.py

run:
	py dumby.py

clean:
	if exist build rmdir /s /q build
