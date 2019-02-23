#!/bin/bash
#O_O learn2
#fvw vimtexhappy@gmail.com
#setting
game_with=15
game_height=25
game_top=2
game_left=10
game_no_wall=1

#tmp
game_id=0
game_sig=0
game_start=0

#Signal
sig_up=25
sig_left=26
sig_right=27
sig_down=28
sig_exit=30

#direction
dirt_up=0
dirt_down=1
dirt_left=2
dirt_right=3

#map data
var_init(){
    usr_level=0
    usr_score=0

    snake_color=4
    snake_head=0
    snake_end=0
    snake_len=1
    snake_cur_x=0
    snake_cur_y=0
    snake_move_dirt=0

    dot_color=3
    dot_cur_x=0
    dot_cur_y=0
}

show_frame() {
    #make game frame
    local i x1 x2 y1 y2
    ((x1 = game_left))
    ((y1 = game_top))
    ((y2 = game_top+game_height+1))
    for ((i=0; i<game_with+2; i++));do
        echo -ne "\033[$y1;${x1}H\033[44;32m==\033[0m"
        echo -ne "\033[$y2;${x1}H\033[44;32m==\033[0m"
        ((x1 += 2))
    done

    ((x1 = game_left))
    ((x2 = game_left+game_with*2+2))
    ((y1 = game_top+1))
    for ((i=0; i<game_height; i++));do
        echo -ne "\033[$y1;${x1}H\033[44;32m||\033[0m"
        echo -ne "\033[$y1;${x2}H\033[44;32m||\033[0m"
        ((y1++))
    done
}

show_txt() {
    local x y 
    local score level
    score=${1:-$usr_score}
    level=${2:-$usr_level}
    ((x = game_left + game_with*2 + 4 + 6))
    ((y = game_top + game_height/3))
    echo -ne "\033[${y};${x}H\033[40;36mScore\033[0m"
    ((y++))
    echo -ne "\033[${y};${x}H\033[40;37m${score}\033[0m"
    ((y+=2))
    echo -ne "\033[${y};${x}H\033[40;36mLevel\033[0m"
    ((y++))
    echo -ne "\033[${y};${x}H\033[40;37m${level}\033[0m"
}

show_end_text(){
    local x y
    len=${#1}
    ((x = game_left + game_with-len/2))
    ((y = game_top + game_height/2 - 1))
    echo -ne "\033[${y};${x}H$1"
    game_start=0
}

show_dot() {
    local show index x y color
    show=$1
    x=${2:-$snake_cur_x}
    y=${3:-$snake_cur_y}
    color=${4:-$snake_color}
    ((x= game_left + 2 + x* 2 ))
    ((y= game_top + 1 + y))
    echo -ne "\033[${y};${x}H"
    if (($show == 1)); then
        echo -ne "\033[1;7;4${color};3${color}m[]\033[0m"
    else
        echo -ne "  "
    fi
}

make_map() {
    local i x y
    ((x = game_left + 2))
    ((y = game_top + 1))
    for ((i=0; i<game_height; i++));do
        echo -ne "\033[$((y+i));${x}H"
        for ((j=0; j<game_with; j++));do
            echo -ne "  "
        done
    done
    snake_color=4
    snake_head=0
    snake_end=0
    snake_len=1
    ((snake_cur_x=RANDOM%(game_with/2)+game_with/4))
    ((snake_cur_y=RANDOM%(game_height/2)+game_height/4))
    snakes=($snake_cur_x $snake_cur_y)
    ((snake_move_dirt=RANDOM % 4))
    show_dot 1
}

dot_new(){
    local dot_x dot_y
    local max_try i
    max_try=200
    while ((max_try--));do
        ((dot_x=RANDOM%game_with))
        ((dot_y=RANDOM%game_height))
        for ((i=snake_end; i<=snake_head; i+=2));do
            ((snakes[i]==dot_x && snakes[i+1]==dot_y)) && break
        done
        ((i>snake_head)) && break 
    done
    if ((max_try>=0));then
        dot_cur_x=$dot_x
        dot_cur_y=$dot_y
        show_dot 1 $dot_x $dot_y $dot_color
    else
        show_end_text "Very good!"
    fi
}

snake_go() {
    local go_x go_y
    go_x=$snake_cur_x
    go_y=$snake_cur_y
    try_move=$1
    case $try_move in
        $dirt_up) ((go_y--));;
        $dirt_down) ((go_y++));;
        $dirt_left) ((go_x--));;
        $dirt_right) ((go_x++));;
    esac
    if ((snake_len != 1)) && ((snakes[snake_head-2]==go_x && snakes[snake_head-1]== go_y));then
        #don't move
        return
    fi
    #hold move dirt
    snake_move_dirt=$try_move
    if ((game_no_wall == 1));then
        ((go_x<0)) && ((go_x+=game_with))
        ((go_x>=game_with)) && ((go_x-=game_with))
        ((go_y<0)) && ((go_y+=game_height))
        ((go_y>=game_height)) && ((go_y-=game_height))
    else
        if ((go_x<0 || go_x>=game_with || go_y<0 || go_y>=game_height));then
            show_end_text "Game over!"
            return
        fi
    fi

    #local i index
    ##snake_end over max->0 is ok too.
    #((index=snake_end))
    #for ((i=0; i<snake_len; i++));do
        #((snakes[index]==go_x && snakes[index+1]==go_y)) && break
        #((index+=2))
    #done
    #if ((i<snake_len));then
        #show_end_text "Game over!"
        #return
    #fi
    #array index very long 2^6x
    local i
    for ((i=snake_end; i<=snake_head; i+=2));do
        ((snakes[i]==go_x && snakes[i+1]==go_y)) && break
    done
    if ((i<=snake_head));then
        show_end_text "Game over!"
        return
    fi
    ((snake_head+=2))
    snakes[snake_head]=$go_x
    snakes[snake_head+1]=$go_y
    snake_cur_x=$go_x
    snake_cur_y=$go_y
    show_dot 1
    if ((go_x == dot_cur_x && go_y == dot_cur_y));then
        ((snake_len++))
        ((usr_score++))
        ((usr_level=usr_score/10))
        ((usr_level>20)) && ((usr_level=20))
        show_txt
        dot_new
    else
        show_dot 0 ${snakes[$snake_end]} $((snakes[snake_end+1]))
        unset snakes[snake_end]
        unset snakes[$((snake_end+1))]
        ((snake_end+=2))
    fi
}

init_game(){
    clear
    var_init
    show_frame
    show_txt 
    make_map
    dot_new
}

exit_game(){
    exit 0
}


game_routine(){
    local i
    trap "game_sig=$sig_down"    $sig_down
    trap "game_sig=$sig_left"    $sig_left
    trap "game_sig=$sig_right"   $sig_right
    trap "game_sig=$sig_up"      $sig_up
    trap "game_sig=$sig_exit"    $sig_exit
    init_game
    while ((game_sig == 0));do
        sleep 0.02
    done
    game_start=1
    while :;do
        while ((game_start));do
            for ((i=20-usr_level; i>=0; i--));do
                case $game_sig in
                    $sig_down ) snake_go $dirt_down;;
                    $sig_left ) snake_go $dirt_left;;
                    $sig_right) snake_go $dirt_right;;
                    $sig_up   ) snake_go $dirt_up;;
                    $sig_exit ) exit_game;;
                esac
                if ((game_sig != 0));then
                    game_sig=0
                    break
                fi
                sleep 0.02
            done
            if ((i<0));then
                snake_go $snake_move_dirt
            fi
        done
        while ((game_sig == 0));do
            sleep 0.02
        done
        game_start=1
        init_game
    done
}


key_exit(){
    stty $tty
    echo -ne "\033[?25h"
    kill -$sig_exit $game_pid
    clear
    exit
}

key_rountine(){
    game_pid=$1
    tty=$(stty -g)
    echo -ne "\033[?25l"
    trap "key_exit;" INT TERM
    trap "key_exit;" $sig_exit

    local key keys sig
    local ESC 
    #ESC=$(echo -ne "\033")
    ESC=$'\033'
    keys=(0 0 0)
    while :;do
        sig=0
        read -s -n 1 key
        keys[0]=${keys[1]}
        keys[1]=${keys[2]}
        keys[2]=$key
        if [[ ${keys[0]} == $ESC && ${keys[1]} == "[" ]] ;then
            case ${keys[2]} in
                "A") sig=$sig_up;;
                "B") sig=$sig_down;;
                "D") sig=$sig_left;;
                "C") sig=$sig_right;;
            esac
        elif [[ ${keys[2]} == "q" ]];then
            key_exit 
        fi
        if (($sig != 0));then
            kill -$sig $1
        fi
    done
}

if [ "$1" == "game" ] ;then
    game_routine
else
    bash $0 game &
    key_rountine $!
fi