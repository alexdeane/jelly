-module(jelly_json).

-export([
    decode/1
]).

-if(?OTP_RELEASE < 27).
-define(bad_version, 
    error({erlang_otp_27_required, << "Insufficient Erlang/OTP version.

`jelly_json` uses the Erlang `json` module introduced in Erlang/OTP 27.
You are using Erlang/OTP "/utf8, (integer_to_binary(?OTP_RELEASE))/binary, "
Please upgrade your Erlang install.
"/utf8>>})).

decode(_) -> ?bad_version.
-else.

decode(Json) ->
    try
        {ok, json:decode(Json)}
    catch
        error:unexpected_end -> {error, unexpected_end_of_input};
        error:{invalid_byte, Byte} -> {error, {unexpected_byte, hex(Byte)}};
        error:{unexpected_sequence, Byte} -> {error, {unexpected_sequence, Byte}}
    end.

hex(I) ->
    H = list_to_binary(integer_to_list(I, 16)),
    <<"0x"/utf8, H/binary>>.

-endif.