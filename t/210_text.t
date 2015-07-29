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

note 'text';
{
    $t->app->routes->post("/test/text")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('text0')->text,                 'text0 валидация';
        ok $v->has_error('text0'),                      'text0 ошибка';
        is $v->param('text0'), undef,                   'text0 пустая строка';

        ok $v->required('text1')->text,                 'text1 валидация';
        ok ! $v->has_error('text1'),                    'text1 ошибки нет';
        is $v->param('text1'), 'aaa111bbb222 ccc333',   'text1 значение';

        ok $v->required('text2')->text,                 'text2 валидация';
        ok ! $v->has_error('text2'),                    'text2 ошибки нет';
        is $v->param('text2'), ' aaa ',                 'text2 значение';

        ok $v->required('text3')->text,         'text3 валидация';
        ok ! $v->has_error('text3'),            'text3 ошибки нет';
        is $v->param('text3'), '   ',           'text3 значение пробелы';

        ok $v->required('text_utf8')->text,     'text_utf8 валидация';
        ok ! $v->has_error('text_utf8'),        'text_utf8 ошибки нет';
        is $v->param('text_utf8'), '★абвгд★',   'text_utf8 значение';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/text", form => {
        text0    => '',
        text1    => 'aaa111bbb222 ccc333',
        text2    => ' aaa ',
        text3    => '   ',

        text_utf8 => '★абвгд★',
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

