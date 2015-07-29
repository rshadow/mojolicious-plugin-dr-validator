#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 19;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::DR::Validator';
}

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;
        $self->plugin('DR::I18n');
        $self->plugin('DR::Validator');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'str';
{
    $t->app->routes->post("/test/str")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('str0')->str,               'str0 валидация';
        ok $v->has_error('str0'),                   'str0 ошибка';
        is $v->param('str0'), undef,                'str0 пустая строка';

        ok $v->required('str1')->str,               'str1 валидация';
        ok ! $v->has_error('str1'),                 'str1 ошибки нет';
        is $v->param('str1'), 'aaa111bbb222 ccc333','str1 значение';

        ok $v->required('str2')->str,               'str2 валидация';
        ok ! $v->has_error('str2'),                 'str2 ошибки нет';
        is $v->param('str2'), 'aaa',                'str2 значение';

        ok $v->required('str3')->str,               'str3 валидация';
        ok ! $v->has_error('str3'),                 'str3 ошибки нет';
        is $v->param('str3'), '',                   'str3 значение пробелы';

        ok $v->required('str_utf8')->str,           'str_utf8 валидация';
        ok ! $v->has_error('str_utf8'),             'str_utf8 ошибки нет';
        is $v->param('str_utf8'), '★абвгд★',        'str_utf8 значение';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/str", form => {
        str0    => '',
        str1    => 'aaa111bbb222 ccc333',
        str2    => ' aaa ',
        str3    => '   ',

        str_utf8 => '★абвгд★',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

