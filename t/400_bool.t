#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 43;
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

note 'bool';
{
    $t->app->routes->post("/test/bool")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->checked('unknown')->bool,    'unknown валидация';
        ok ! $v->has_error('unknown'),      'unknown ошибки нет';
        is $v->param('unknown'), 0,         'unknown не передано';

        ok $v->checked('bool0')->bool,      'bool0 валидация';
        ok $v->has_error('bool0'),          'bool0 ошибка';
        is $v->param('bool0'), undef,       'bool0 неизвестная строка';

        ok $v->checked('bool1')->bool,      'bool1 валидация';
        ok ! $v->has_error('bool1'),        'bool1 ошибки нет';
        is $v->param('bool1'), 1,           'bool1 1';

        ok $v->checked('bool2')->bool,      'bool2 валидация';
        ok ! $v->has_error('bool2'),        'bool2 ошибки нет';
        is $v->param('bool2'), 1,           'bool2 true';

        ok $v->checked('bool3')->bool,      'bool3 валидация';
        ok ! $v->has_error('bool3'),        'bool3 ошибки нет';
        is $v->param('bool3'), 1,           'bool3 yes';

        ok $v->checked('bool4')->bool,      'bool4 валидация';
        ok ! $v->has_error('bool4'),        'bool4 ошибки нет';
        is $v->param('bool4'), 0,           'bool4 0';

        ok $v->checked('bool5')->bool,      'bool5 валидация';
        ok ! $v->has_error('bool5'),        'bool5 ошибки нет';
        is $v->param('bool5'), 0,           'bool5 false';

        ok $v->checked('bool6')->bool,      'bool6 валидация';
        ok ! $v->has_error('bool6'),        'bool6 ошибки нет';
        is $v->param('bool6'), 0,           'bool6 no';

        ok $v->checked('bool7')->bool,      'bool7 валидация';
        ok ! $v->has_error('bool7'),        'bool7 ошибки нет';
        is $v->param('bool7'), 0,           'bool7 пустая строка';

        ok $v->checked('bool8')->bool,      'bool8 валидация';
        ok ! $v->has_error('bool8'),        'bool8 ошибки нет';
        is $v->param('bool8'), 0,           'bool8 строка из пробелов';

        ok $v->checked('bool9')->bool,      'bool9 валидация';
        ok ! $v->has_error('bool9'),        'bool9 ошибки нет';
        is $v->param('bool9'), 1,           'bool9 true с пробелами';

        ok $v->checked('bool10')->bool,     'bool10 валидация';
        ok ! $v->has_error('bool10'),       'bool10 ошибки нет';
        is $v->param('bool10'), 1,          'bool10 ok';

        ok $v->checked('bool11')->bool,     'bool10 валидация';
        ok ! $v->has_error('bool11'),       'bool10 ошибки нет';
        is $v->param('bool11'), 0,          'bool10 fail';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/bool", form => {
        bool0       => 'aaa',
        bool1       => '1',
        bool2       => 'True',
        bool3       => 'yes',
        bool4       => '0',
        bool5       => 'faLse',
        bool6       => 'no',
        bool7       => '',
        bool8       => '   ',
        bool9       => '  True  ',
        bool10      => 'OK',
        bool11      => 'FAIL',
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
