# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => repeat_each() * (blocks() * 4);

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';

no_long_string();
#no_diff();

run_tests();

__DATA__
=== TEST 1: POST form-urlencoded
--- http_config eval: $::HttpConfig
--- config
    location = /a {
        content_by_lua '
            local http = require "resty.http"
            local httpc = http.new()
            httpc:connect("127.0.0.1", ngx.var.server_port)
            
            local status, headers, body = httpc:request{
                body = "a=1&b=2&c=3",
                path = "/b",
                headers = {
                    ["Content-Type"] = "application/x-www-form-urlencoded",
                }
            }

            ngx.say(body)
            httpc:close()
        ';
    }
    location = /b {
        content_by_lua '
            ngx.req.read_body()
            local args = ngx.req.get_post_args()
            ngx.say("a: ", args.a)
            ngx.say("b: ", args.b)
            ngx.print("c: ", args.c)
        ';
    }
--- request
GET /a
--- response_body
a: 1
b: 2
c: 3
--- no_error_log
[error]
[warn]


