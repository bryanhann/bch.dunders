################################################################
# These dunder functions serve all other sourced functions
# and so this file must be sourced FIRST.
################################################################


#===============================================================
# Suppose we want to use [~/.config/foo] rather than [~/.foo]
# but the foo program only looks at [~/.foo]. We fis this by
# creating an appropriate [~/.config/foo] and calling
#
#     __link__ foo
#===============================================================

__link__ () { [ -e ~/.$1 ] || ln -s ~/.config/$1 ~/.$1 ; }


#===============================================================
# Suppose we want to internally document a function in a
# way that can be inspected at runtime. We do this with the
# function '__DOC__'.
#
#     function foo {
#         __DOC__ 'foo() -> bar'
#         ....
#
# We can later review this by grepping the environment:
#
#     set | grep __DOC__
#
# Note that while the function itself does nothing, by
# prepending it to a line of documentation that line
# is registered in the environment.
#
# TODO (maybe): implement intelligent registration
#===============================================================

__DOC__ () { true ; }


#===============================================================
# Sometimes we need to source an infrastructure before moving on in
# our process. If the infracture is not there we must install it. But
# we wish to avoid race conditions with other processes doing the same
# thing.
#
# The client passes us an installation script along with two flags which
# we will name
#
#     ${fREADY}
#     ${fWAIT}
#
# If ${fREADY} is up we return directly to the caller.
#
# Otherwise we assume that the infrastructure does not exist. We
# ATTEMPT to raise ${fWAIT} as a signal to other procesees that a
# construction is in processes and that they should not interfere.
#
# If our attempt FAILS we assume the infrastructure is being created
# by another process. We enter a SUSPEND state and wait for ${fREADY}
# to be raised, and then return directly to the caller.
#
# If our attempt SUCCEEDS then we construct the infrastructure by
# invoking ${constucture}. When ${constructure} returns we raise
# ${fREADY}, lower ${fWAIT}, and return control to the caller.
#
# XXX This is fragile in practice. Be careful with your choice of
# flags. The danger of an infinite SUSPEND loop exists if there
# was an earlier incomplete construction.
# of trying to create a folder.

__tryinstall__ () {
    local NAME=${1}
    local FUNC=${3}
    local DONE=${2}.ready
    local WAIT=${2}.wait
    raise_DONE  () { touch ${DONE}; return 0; }
    lower_WAIT  () { rmdir ${WAIT}; return 0; }
    raise_WAIT  () { mkdir ${WAIT} 2> /dev/null && return 0 || return 1;  }     # plant the fWAIT flag
    SUSPEND     () { echo WAITING FOR ${NAME} TO INSTALL; while [ ! -f ${DONE} ]; do sleep 1;echo -n .;done;echo; }

    [ -f ${DONE}  ] && return
    raise_WAIT && echo INSTALLING ${NAME} && ${FUNC} && raise_DONE && lower_WAIT  || SUSPEND
}




__export__ () {
    # A convenience function to allow prettier exports. It affords white space.
    export $1=$2
}
__map__ () {fn=$1;shift;for ii in $*;do $fn $ii;done;}
__ls__  () {for f in $(/bin/ls ${1});do echo ${1}/${f};done;}

