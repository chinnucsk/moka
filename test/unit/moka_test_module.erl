%%% @doc This module is part of the moka_mod_utils_eunit test

-module(moka_test_module).

-export([foo/0, remote_bar/0]).

foo() -> foo.

remote_bar() ->
    moka_test_module2:bar().
