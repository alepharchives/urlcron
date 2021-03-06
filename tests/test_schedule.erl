-module(test_schedule).
-include_lib("eunit/include/eunit.hrl").
-include("urlcron.hrl").

setup_test() ->
    Config = erlcfg:new("urlcron.conf"),
    urlcron_mochiweb:start(Config),
    urlcron_scheduler:start(Config).

start_enabled_test() ->
    StartTime = urlcron_util:get_future_time(600000),
    {ok, Pid} = urlcron_schedule:start("schedule01", StartTime),
    ?assert(is_process_alive(Pid) == true),
    urlcron_schedule:stop(Pid).

start_disabled_test() ->
    StartTime = urlcron_util:get_future_time(600000),
    {ok, Pid} = urlcron_schedule:start("schedule02", StartTime),
    ?assert(is_process_alive(Pid) == true),
    urlcron_schedule:stop(Pid).

schedule_runs_and_exits_test() ->
    StartTime = urlcron_util:get_future_time(1000),
    {ok, Pid} = urlcron_schedule:start("schedule03", StartTime),
    schedule_store:add("schedule03", Pid, StartTime, "http://localhost:8118/echo/schedule03", enabled),
    ?assert(is_process_alive(Pid) == true),
    timer:sleep(2000),
    ?assert(is_process_alive(Pid) == false).

fetch_url_test() ->
    StartTime = urlcron_util:get_future_time(1000),
    urlcron_scheduler:create("schedule4", StartTime, "http://localhost:8118/echo/fetch_url_test"),

    timer:sleep(1200),

    #schedule{url_status=UrlStatus, url_content=UrlContent, status=Status, pid=Pid} = schedule_store:get("schedule4"),
    ?assertEqual({200, "fetch_url_test", completed, undefined}, {UrlStatus, UrlContent, Status, Pid}).

teardown_test() ->
    Config = erlcfg:new("urlcron.conf"),
    urlcron_mochiweb:stop(),
    urlcron_scheduler:stop(),
    schedule_store:destroy(Config).
