export EZRASSOR_WORKSPACE="$HOME/ezrassor_ws"

alias ertb="ezrassor_toolbox"
alias ezrassor-toolbox="ezrassor_toolbox"
alias init-ros-melodic=". /opt/ros/melodic/setup.bash"
alias init-ezrassor-melodic-devel='. $EZRASSOR_WORKSPACE/devel/setup.bash'
alias init-ezrassor-melodic-install='. $EZRASSOR_WORKSPACE/install/setup.bash'

ezrassor_toolbox() {
  if [ $# -lt 1 ]; then
    _ezrassor_show_help
    return 1
  fi

  for action in $@; do
    case "$action" in
      "help"|"--help")
        _ezrassor_show_help
        ;;
      "setup"|"--setup")
        _ezrassor_setup_environment
        ;;
      "link"|"--link")
        _ezrassor_link_package
        ;;
      "resolve"|"--resolve")
        _ezrassor_resolve_dependencies
        ;;
      "build"|"--build")
        _ezrassor_build_packages
        ;;
      "install"|"--install")
        _ezrassor_install_packages
        ;;
      "test"|"--test")
        _ezrassor_test_packages
        ;;
      "clean"|"--clean")
        _ezrassor_clean_environment
        ;;
      "nuke"|"--nuke")
        _ezrassor_nuke_environment
        ;;
      *)
        _ezrassor_show_help
        ;;
    esac
    status=$?
    if [ $status -ne 0 ]; then
      return $status
    fi
  done
}

_ezrassor_success() {
  printf "\033[0;32mezrassor_toolbox: %s\033[0m\n" "$1"
}

_ezrassor_error() {
  printf "\033[0;31mezrassor_toolbox: %s\033[0m\n" "$1"
}

_ezrassor_show_help() {
  printf "%s\n" \
    "usage:" \
    "  $ ezrassor_toolbox <tool>" \
    "" \
    "tools:" \
    "  setup     setup the underlying Catkin workspace" \
    "  link      link the current directory as a ROS package" \
    "  resolve   install dependencies for all packages" \
    "  build     build all packages" \
    "  install   install all packages under a fake root" \
    "  test      run package integration tests" \
    "  clean     remove build artifacts" \
    "  nuke      remove everything" \
    "  help      show this menu" \
    "" \
    "aliases:" \
    "  ertb                            map to ezrassor_toolbox" \
    "  ezrassor-toolbox                map to ezrassor_toolbox" \
    "  init-ros-melodic                initialize ROS Melodic" \
    "  init-ezrassor-melodic-devel     source EZRASSOR devel space" \
    "  init-ezrassor-melodic-install   source EZRASSOR install space" \
    "" \
    "environment:" \
    "  \$EZRASSOR_WORKSPACE   path to the workspace directory"
}

_ezrassor_setup_environment() {
  catkin_init_workspace -h >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    _ezrassor_error "catkin not found... is ROS initialized?"
    return 1
  fi

  rm -r -f "$EZRASSOR_WORKSPACE"
  mkdir -p "$EZRASSOR_WORKSPACE/src"
  catkin_init_workspace "$EZRASSOR_WORKSPACE/src" >/dev/null 2>&1
  _ezrassor_success "created workspace at $EZRASSOR_WORKSPACE"
}

_ezrassor_link_package() {
  if [ ! -d "$EZRASSOR_WORKSPACE/src" ]; then
    _ezrassor_error "workspace not found... have you run setup?"
    return 1
  fi

  if [ ! -f "package.xml" ]; then
    _ezrassor_error "no package.xml file found... is this a ROS package?"
    return 1
  fi

  package_path="$PWD"
  package_name="$(basename "$package_path")"
  if [ -L "$EZRASSOR_WORKSPACE/src/$package_name" ]; then
    rm -f "$EZRASSOR_WORKSPACE/src/$package_name"
    ln -s "$package_path" "$EZRASSOR_WORKSPACE/src/$package_name"
    _ezrassor_success "relinked package $package_name"
  else
    ln -s "$package_path" "$EZRASSOR_WORKSPACE/src/$package_name"
    _ezrassor_success "linked package $package_name"
  fi
}

_ezrassor_resolve_dependencies() {
  rosdep install --from-paths "$EZRASSOR_WORKSPACE/src" --ignore-src -y
  _ezrassor_success "all dependencies resolved"
}

_ezrassor_build_packages() {
  catkin_make -h >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    _ezrassor_error "catkin not found... is ROS initialized?"
    return 1
  fi

  catkin_make -C "$EZRASSOR_WORKSPACE"
  _ezrassor_success "all packages built"
}

_ezrassor_install_packages() {
  catkin_make -h >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    _ezrassor_error "catkin not found... is ROS initialized?"
    return 1
  fi

  catkin_make -C "$EZRASSOR_WORKSPACE" install
  _ezrassor_success "all packages installed"
}

_ezrassor_test_packages() {
  catkin_make -h >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    _ezrassor_error "catkin not found... is ROS initialized?"
    return 1
  fi

  catkin_make -C "$EZRASSOR_WORKSPACE" run_tests
  catkin_test_results "$EZRASSOR_WORKSPACE"
  _ezrassor_success "all tests executed"
}

_ezrassor_clean_environment() {
  rm -r -f "$EZRASSOR_WORKSPACE/devel"
  rm -r -f "$EZRASSOR_WORKSPACE/build"
  rm -r -f "$EZRASSOR_WORKSPACE/install"
  _ezrassor_success "build artifacts removed"
}

_ezrassor_nuke_environment() {
  rm -r -f "$EZRASSOR_WORKSPACE"
  _ezrassor_success "environment nuked"
}
