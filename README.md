# NAME
Donki - Simple Local Management Tool of Repositories

# DESCRIPTION
Donki can local manage repositories that have already existed in remote (GitHub, BitBucket, etc...).  
This application can do several operation for remote repositories.  
For example, install in local environment, uninstall from local, update, and more.  
If you want to know functions of Donki, please refer the following section or execute Donki with "--help" option.  
  
This application received an idea from Vim plug-in management tools ([pathogen](https://github.com/tpope/vim-pathogen), 
[NeoBundle](https://github.com/Shougo/neobundle.vim), [Vundle](https://github.com/gmarik/vundle), etc).  
These tools are very cool. I want to use them on not only Vim, so made this.

# HOW TO INSTALL
Setup Donki...

    $ git clone git://github.com/moznion/Donki.git /install/path/as/you/like
    $ cd /install/path/as/you/like/Donki
    $ ./donki.rb init

Then, '.donkirc' file is put on your home directory.  
And please write some settings into rc file.  
(Please refer to the [example\_donkirc](https://github.com/moznion/Donki/blob/master/example_donkirc).)  
  
And configuration alias to donki.rb, as you like.

# USAGE
**Usage: ./donki.rb [options] [command]**  
  
**Commands**  

    init                              Initialize  
    install                           Install the all of repositories that are registered in rc file  
    update [repository(s) name]       Update installed repositories  
                                      If [repositorie(s) name] is not specified, then update the all of registered repositories  
    uninstall [repository(s) name]    Uninstall repositories  
                                      If [repositorie(s) name] is not specified, then uninstall the all of repositories  
    reinstall                         Install the all of repositories after remove the all of them  
    list                              Show the list of installed repositories  
    --help                            Show the usage.  

**Options**  

    -p=[protocol]                     This option can specify using protocol. (Now, 'git', 'https' and 'ssh' protocol are available)
  
# HOW TO WRITE .donkirc
.donkirc conform to the JSON or YAML format.  
Please refer the [example\_donkirc.json](https://github.com/moznion/Donki/blob/master/example_donkirc.json) and [example\_donkirc.yml](https://github.com/moznion/Donki/blob/master/example_donkirc.yml).  

# DEPENDENCIES
- Ruby 1.9.3 or later version
- [ruby-git](https://rubygems.org/gems/git)

# ORIGIN OF A NAME
<http://www.donki.com/index.php>  
Thanks! And I want some coupons!

# LICENSE
MIT
