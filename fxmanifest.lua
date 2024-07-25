fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'Interact'
author 'Fivecore'
description ''
version '1.0.0'

shared_scripts {
	'@ox_lib/init.lua'
}

client_scripts {
	'script/client/Controller.lua'
}

server_scripts {
	-- 'script/server/Controller.lua'
}

dependencies {
  'ox_lib'
}

escrow_ignore {

}