default:
	@echo "No Default make command configured"
	@echo "Please use either"
	@echo "	- make multimc"
	@echo "	- make curseforge"
	@echo "	- make modrinth"
	@echo "	- make technic"
	@echo "	- make server"
	@echo "	- make all"
	@echo ""
	@echo "Curseforge will make a curseforge import file"
	@echo ""
	@echo "Modrinth will make a modrinth import file"
	@echo ""
	@echo "Multimc will make a multimc zip file which contains"
	@echo "   the packwiz updater"
	@echo ""
	@echo "Technic will make a technic pack zip"
	@echo ""
	@echo "Server will make a server pack zip"
	@echo "   This will include the packwiz updater,"
	@echo "   but will not be configured to run by default"
	@echo ""
	@echo "All will make all packs it can"
	@echo ""

PACKNAME := $(notdir $(CURDIR))
PACKURL := $(shell pw detect)

curseforge: refresh
	-mkdir .build
	@echo "Making Curseforge pack"
	packwiz curseforge export --pack-file .minecraft/pack.toml
	mv ./*.zip ./.build/${PACKNAME}-curseforge.zip

modrinth: refresh
	-mkdir .build
	@echo "Making Modrinth pack"
	packwiz modrinth export --pack-file .minecraft/pack.toml 
	mv ./*.mrpack ./.build/${PACKNAME}-modrinth.mrpack

multimc: refresh
	-mkdir .build
	@echo "Making MultiMC pack"
	7z d .build/${PACKNAME}-multimc.zip ./* -r
	7z d .build/${PACKNAME}-multimc.zip ./.minecraft -r
	@sed -i 's#{PACKURL}#${PACKURL}#' instance.cfg
	7z a .build/${PACKNAME}-multimc.zip ./* -r
	7z a .build/${PACKNAME}-multimc.zip ./.minecraft -r
	7z d .build/${PACKNAME}-multimc.zip ./.build ./.minecraft/mods ./.minecraft/pack.toml ./.minecraft/index.toml -r
	@sed -i 's#${PACKURL}#{PACKURL}#' instance.cfg


technic: refresh
	-mkdir .build
	@echo "Making Technic pack"
	-rm -rf .technic
	-cp -r .minecraft .technic
	cp ${PACKNAME}_icon.png .technic/icon.png
	cd .technic && java -jar ../.minecraft/packwiz-installer-bootstrap.jar ../.minecraft/pack.toml && cd ..
	-rm -rf .technic/packwiz* .technic/index.toml .technic/pack.toml .technic/mods/*.toml
	7z d .build/${PACKNAME}-technic.zip ./* ./.* -r
	7z a .build/${PACKNAME}-technic.zip ./.technic/* -r

server: refresh
	-mkdir .build
	@echo "Making Server pack"
	-rm -rf .server
	-cp -r .minecraft .server
	cp ${PACKNAME}_icon.png .server/server-icon.png
	cd .server && java -jar ../.minecraft/packwiz-installer-bootstrap.jar -s server ../.minecraft/pack.toml && cd ..
	7z d .build/${PACKNAME}-server.zip ./* ./.* -r
	7z a .build/${PACKNAME}-server.zip ./.server/* -r

preClean: refresh
	-rm -rf .build
	-rm -rf .server
postClean: refresh
	-rm -rf .technic
	-rm -rf .server
	-git gc --aggressive --prune
clean: preClean postClean

all: preClean curseforge modrinth multimc technic server postClean

refresh:
	cd .minecraft && packwiz refresh

update-packwiz:
	go install github.com/packwiz/packwiz@latest
	go install github.com/Merith-TK/packwiz-wrapper/cmd/pw@main
	clear
	@echo "Packwiz has been Updated"

run-server:
	cd .minecraft && pw refresh && cd ..
	-mkdir .run
	echo "eula=true" > .run/eula.txt
	cd .run && java -jar ../.minecraft/packwiz-installer-bootstrap.jar ../.minecraft/pack.toml -s server && cd ..
	cd .run && java -Xmx2G -Xms2G -jar server.jar nogui && cd ..
