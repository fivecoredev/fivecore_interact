fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'Interact'
author 'Fivecore'
description ''
version '1.0.0'

shared_script '@ox_lib/init.lua'

client_scripts {
  'client/Controller.lua'
}

dependencies {
  'ox_lib'
}