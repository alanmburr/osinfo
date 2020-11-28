#!/usr/bin/env /usr/bin/bash

#Copyright (C) 2020  Alan Burr
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <https://www.gnu.org/licenses/>.

wm () {
    if [ -z $(echo $XDG_CURRENT_DESKTOP) ]; then
        echo -e "\c"
    elif [ -n $(echo $XDG_CURRENT_DESKTOP) ]; then
        echo $XDG_CURRENT_DESKTOP
    fi

    if [ -z $(echo $GDMSESSION) ]; then
        echo ""
    elif [ -n $(echo $GDMSESSION) ]; then
        echo $GDMSESSION
    fi
}

theme () {
    detect_gnome () {
        ps -e | grep -E '^.* gnome-session$' > /dev/null
        if [ $? -ne 0 ]; then
	        return 0
        fi
        VERSION=`gnome-session --version | awk '{print $2}'`
        DESKTOP="GNOME"
        return 1
    }

    detect_kde () {
        ps -e | grep -E '^.* kded4$' > /dev/null
        if [ $? -ne 0 ]; then
            return 0
        else    
        VERSION=`kded4 --version | grep -m 1 'KDE' | awk -F ':' '{print $2}' | awk '{print $1}'`
        DESKTOP="KDE"
        return 1
    fi
    }

    detect_unity () {
        ps -e | grep -E 'unity-panel' > /dev/null
        if [ $? -ne 0 ]; then
	        return 0
        fi
        VERSION=`unity --version | awk '{print $2}'`
        DESKTOP="UNITY"
        return 1
    }

    detect_xfce () {
        ps -e | grep -E '^.* xfce4-session$' > /dev/null
        if [ $? -ne 0 ]; then
	        return 0
        fi
        VERSION=`xfce4-session --version | grep xfce4-session | awk '{print $2}'`
        DESKTOP="XFCE"
        return 1
    }

    detect_cinnamon () {
        ps -e | grep -E '^.* cinnamon$' > /dev/null
        if [ $? -ne 0 ]; then
	        return 0
        fi
        VERSION=`cinnamon --version | awk '{print $2}'`
        DESKTOP="CINNAMON"
        return 1
    }

    detect_mate () {
        ps -e | grep -E '^.* mate-panel$' > /dev/null
        if [ $? -ne 0 ]; then
	        return 0
        fi
        VERSION=`mate-about --version | awk '{print $4}'`
        DESKTOP="MATE"
        return 1
    }

    detect_lxde () {
        ps -e | grep -E '^.* lxsession$' > /dev/null
        if [ $? -ne 0 ]; then
	        return 0
        fi

        # We can detect LXDE version only thru package manager
        which apt-cache > /dev/null 2> /dev/null
        if [ $? -ne 0 ]; then
	        which yum > /dev/null 2> /dev/null
	        if [ $? -ne 0 ]; then
	            VERSION='Could not detect version'
	        else
	            # For Fedora
	            VERSION=`yum list lxde-common | grep lxde-common | awk '{print $2}' | awk -F '-' '{print $1}'`
	    fi
        else    
	        # For Lubuntu and Knoppix
	        VERSION=`apt-cache show lxde-common /| grep 'Version:' | awk '{print $2}' | awk -F '-' '{print $1}'`
        fi
        DESKTOP="LXDE"
        return 1
    }

    detect_sugar () {
    if [ "$DESKTOP_SESSION" == "sugar" ]; then
	    VERSION=`python -c "from jarabe import config; print config.version"`
	    DESKTOP="SUGAR"
    else
	    return 0
    fi
    }


    DESKTOP=""
    if detect_unity; then
        if detect_kde; then
	    if detect_gnome; then
	        if detect_xfce; then
		    if detect_cinnamon; then
		        if detect_mate; then
			    if detect_lxde; then
			        detect_sugar
			    fi
		        fi
		    fi
	        fi
	    fi
        fi
    fi


    if [ "$1" == '-v' ]; then
        echo $VERSION
    else
        if [ "$1" == '-n' ]; then
	        echo $DESKTOP
        else
	        echo $DESKTOP $VERSION
        fi
    fi
}

meminfo () {
    used=$(free -m | grep Mem | sed -e 's/Mem:          //' | awk '{print $2, $1, $3}' | awk '{print $1}')
    total=$(free -m | grep Mem | sed -e 's/Mem:          //' | awk '{print $1, $3, $2}' | awk '{print $1}')
    free=$(free -m | grep Mem | sed -e 's/Mem:          //' | awk '{print $3, $2, $1}' | awk '{print $1}')
    percent=$(free -m | grep Mem | awk '{print ($3/$2)*100}')
    echo "$used MiB/$total MiB, $free MiB free ($percent% used)"
}

architecture () {
    case $(uname -i) in
        x86_64)
            echo "amd64 (64-bit)" ;;
        
        i*86)
            echo "$(uname -i) (32-bit)" ;;
        *)
            echo "Unknown architecture" ;;
    esac
}

infocpu () { 
    cat /proc/cpuinfo | grep 'model name' | sed -e 's/model name//' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 2- 
}

infogpu () {
    if [ -z $(lspci -v | grep 'VGA compatible controller: ' | cut -d ' ' -f 5- | cut -b -25) ]; then
        echo ""
    elif [ -n $(lspci -v | grep 'VGA compatible controller: ' | cut -d ' ' -f 5- | cut -b -25) ]; then
        echo $(lspci -v | grep 'VGA compatible controller: ' | cut -d ' ' -f 5- | cut -b -25)
    fi
}

cannot_detect_errors () {
    if [ -z $(infogpu) ]; then
        gpu_present="False"
    elif [ -z $(wm)]; then
        wm_present="False"
    elif [ -z $(theme) ]; then
        theme_present="False"
    elif [ -n $(infogpu) ]; then
        gpu_present="True"
    elif [ -n $(wm) ]; then
        wm_present="True"
    elif [ -n $(theme) ]; then
        theme_present="True"
    fi

    #none true
    if [ gpu_present = "False" ] && [ wm_present = "False" ] && [ theme_present = "False" ]; then
        echo ""
    #GPU true
    elif [ gpu_present = "True" ] && [ wm_present = "False" ] && [ theme_present = "False"]; then
        echo -e "SPECIAL---------------------------------------------------------:\nGPU: $(infogpu)"
    #wm true
    elif [ gpu_present = "False" ] && [ wm_present = "True" ] && [ theme_present = "False" ]; then
        echo -e "SPECIAL---------------------------------------------------------:\nWM: $(wm)"
    #theme true
    elif [ gpu_present = "False" ] && [ wm_present = "False" ] && [ theme_present = "True" ]; then
        echo -e "SPECIAL---------------------------------------------------------:\nTheme: $(theme)"
    #gpu and wm true, theme false
    elif [ gpu_present = "True" ] && [ wm_present = "True" ] && [ theme_present = "False"]; then
        echo -e "SPECIAL---------------------------------------------------------:\nGPU: $(infogpu)\nWM: $(wm)"
    #gpu and theme true, wm false
    elif [ gpu_present = "True" ] && [ wm_present = "False" ] && [ theme_present = "True"]; then
        echo -e "SPECIAL---------------------------------------------------------:\nGPU: $(infogpu)\nTheme: $(theme)"
    #theme and wm true, gpu false
    elif [ gpu_present = "False" ] && [ wm_present == "False" ] && [ theme_present = "True" ]; then
        echo -e "SPECIAL---------------------------------------------------------:\nWM: $(wm)\nTheme: $(theme)"
    fi

    unset gpu_present, wm_present, theme_present
}

uptimeis () {
    if [ $1 = "p" ]; then 
        echo $(uptime -p | sed 's/up //')
    elif [ $1 = "s" ]; then
        echo -e "$(uptime -s | sed 's/-/ /g' | cut -d ' ' -f 1-3 | awk '{print $2, $3, $1}' | sed 's/ /\//g') \c"
        time2convert=$(uptime -s | cut -d ' ' -f2 | cut -d ':' -f1)
        hr=0
        ampm=""
        case ${time2convert} in
            1) hr=1; ampm="AM" ;;
            2) hr=2; ampm="AM" ;;
            3) hr=3; ampm="AM" ;;
            4) hr=4; ampm="AM" ;;
            5) hr=5; ampm="AM" ;;
            6) hr=6; ampm="AM" ;;
            7) hr=7; ampm="AM" ;;
            8) hr=8; ampm="AM" ;;
            9) hr=9; ampm="AM" ;;
            10) hr=10; ampm="AM" ;;
            11) hr=11; ampm="AM" ;;
            12) hr=12; ampm="PM" ;;
            13) hr=1; ampm="PM" ;;
            14) hr=2; ampm="PM" ;;
            15) hr=3; ampm="PM" ;;
            16) hr=4; ampm="PM" ;;
            17) hr=5; ampm="PM" ;;
            18) hr=6; ampm="PM" ;;
            19) hr=7; ampm="PM" ;;
            20) hr=8; ampm="PM" ;;
            21) hr=9; ampm="PM" ;;
            22) hr=10; ampm="PM" ;;
            23) hr=11; ampm="PM" ;;
            24) hr=12; ampm="AM" ;;
        esac
        echo -e "$hr:\c"; echo -e "$(uptime -s | cut -d ' ' -f2 | cut -d ':' -f2-)\c"; echo -e " $ampm"
        unset time2convert, hr, ampm
    fi
}

zenity --info --title "About Linux" --text "\
OS: $(echo $(uname -o): $(lsb_release -d) | sed -e 's/Description: //') \
    \nArch: $(architecture) \
    \nKernel: $(uname -sr) \
    \nHost: $(uname -n) \
    \nMem: $(meminfo) \
    \nCPU: $(infocpu) \
    \nUptime: $(uptimeis p), up since $(uptimeis s) \
    \n$(cannot_detect_errors)
    " \
    --no-wrap --icon-name "gtk-about"

