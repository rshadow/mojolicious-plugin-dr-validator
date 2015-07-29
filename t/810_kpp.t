#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 16;
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

note 'kpp';
{
    $t->app->routes->post("/test/kpp")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('kpp0')->kpp,               'kpp0 валидация';
        ok $v->has_error('kpp0'),                   'kpp0 ошибка';
        is $v->param('kpp0'), undef,                'kpp0 пустая строка';

        ok $v->required('kpp1')->kpp,               'kpp1 валидация';
        ok $v->has_error('kpp1'),                   'kpp1 ошибка';
        is $v->param('kpp1'), undef,                'kpp1 значение неверное';

        ok $v->required('kpp2')->kpp,               'kpp2 валидация';
        ok ! $v->has_error('kpp2'),                 'kpp2 ошибки нет';
        is $v->param('kpp2'), '370601001',         'kpp2 длинна 10';

        ok $v->required('kpp3')->kpp,               'kpp3 валидация';
        ok $v->has_error('kpp3'),                   'kpp3 ошибка';
        is $v->param('kpp3'), undef,                'kpp3 значение неверное';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/kpp", form => {
        kpp0    => '',
        kpp1    => 'aaa111bbb222 ccc333',
        kpp2    => ' 370601001 ',
        kpp3    => ' 3706010012  ',
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

