#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 20;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::DR::Validator';
    use_ok 'Mail::RFC822::Address';
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

note 'email';
{
    $t->app->routes->post("/test/email")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('unknown')->email,          'unknown валидация';
        ok $v->has_error('unknown'),                'unknown ошибка';
        is $v->param('unknown'), undef,             'unknown не передано';

        ok $v->required('email1')->email,           'email1 валидация';
        ok $v->has_error('email1'),                 'email1 ошибка';
        is $v->param('email1'), undef,              'email1 пустая строка';

        ok $v->required('email2')->email,           'email2 валидация';
        ok $v->has_error('email2'),                 'email2 ошибка';
        is $v->param('email2'), undef,              'email2 не email';

        ok $v->required('email3')->email,           'email3 валидация';
        ok ! $v->has_error('email3'),               'email3 ошибки нет';
        is $v->param('email3'), 'a@b.ru',           'email3 email';

        ok $v->required('email4')->email,           'email4 валидация';
        ok ! $v->has_error('email4'),               'email4 ошибки нет';
        is $v->param('email4'), 'a@b.ru',           'email4 email с пробелами';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/email", form => {
        email1      => '',
        email2      => 'aaa',
        email3      => 'a@b.ru',
        email4      => '  a@b.ru  ',
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

