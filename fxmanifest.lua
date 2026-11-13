fx_version 'cerulean'
games {'rdr3'}
lua54 'yes'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'ez_actionjobs'
author 'Rayaan Uddin'
version '2.0.0'
description 'Singleplayer jobs (construction, sweeping, ...) players do for money. Pay grows with experience'

-- jo_libs hosts the menu and prompts, and the hammer minigame (html/, loaded by client/minigame.lua) next to them
ui_page 'nui://jo_libs/nui/index.html'

jo_libs {
    'nui',
    'menu',
    'prompt-nui',
    'callback',
    'notification',
    'blip',
    'utils',
    'framework-bridge',
    'database',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/**/*',
}

shared_scripts {
    '@jo_libs/init.lua',
    'shared/config.lua',
    'shared/lang.lua',
    'shared/helpers.lua',
}

client_scripts {
    'client/minigame.lua',
    'client/main.lua',
    'client/job.lua',
    'client/menu.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/config.lua',
    'server/framework.lua',
    'server/main.lua',
}

dependencies {
    'jo_libs',
    'oxmysql',
    'vorp_core',
}
