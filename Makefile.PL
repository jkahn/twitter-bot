use inc::Module::Install;

name     'Twitter-Bot';
all_from 'lib/Twitter/Bot.pm';
author   'Jeremy G. KAHN <kahn@cpan.org>';

build_requires 'Test::More';

auto_install;

WriteAll;

