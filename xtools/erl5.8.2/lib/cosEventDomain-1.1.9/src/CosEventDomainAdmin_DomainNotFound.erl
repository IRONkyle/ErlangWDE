%%------------------------------------------------------------
%%
%% Implementation stub file
%% 
%% Target: CosEventDomainAdmin_DomainNotFound
%% Source: /net/isildur/ldisk/daily_build/r14b01_prebuild_opu_o.2010-12-07_16/otp_src_R14B01/lib/cosEventDomain/src/CosEventDomainAdmin.idl
%% IC vsn: 4.2.25
%% 
%% This file is automatically generated. DO NOT EDIT IT.
%%
%%------------------------------------------------------------

-module('CosEventDomainAdmin_DomainNotFound').
-ic_compiled("4_2_25").


-include("CosEventDomainAdmin.hrl").

-export([tc/0,id/0,name/0]).



%% returns type code
tc() -> {tk_except,"IDL:omg.org/CosEventDomainAdmin/DomainNotFound:1.0",
                   "DomainNotFound",[]}.

%% returns id
id() -> "IDL:omg.org/CosEventDomainAdmin/DomainNotFound:1.0".

%% returns name
name() -> "CosEventDomainAdmin_DomainNotFound".


