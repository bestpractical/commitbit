use inc::Module::Install;

name('CommitBit');
all_from('lib/CommitBit.pm');
requires('Jifty' => '0.60728');
requires('Text::Password::Pronounceable' => '0');
requires('UNIVERSAL::require');
requires('Module::CoreList');
requires('Path::Class');
WriteAll;
