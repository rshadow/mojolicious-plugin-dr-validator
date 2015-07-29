#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 31;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::DR::Validator';
    use_ok 'DateTime';
    use_ok 'DateTime::Format::DateParse';
    use_ok 'POSIX', qw(strftime);
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

note 'time';
{
    $t->app->routes->post("/test/time")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('time0')->time,         'time0 валидация';
        ok $v->has_error('time0'),              'time0 ошибка';
        is $v->param('time0'), undef,           'time0 пустая строка';

        ok $v->required('time1')->time,         'time1 валидация';
        ok ! $v->has_error('time1'),            'time1 ошибки нет';
        is $v->param('time1'), '00:00:00',      'time1 дата РФ';

        ok $v->required('time2')->time,         'time2 валидация';
        ok ! $v->has_error('time2'),            'time2 ошибки нет';
        is $v->param('time2'), '00:00:00',      'time2 дата SQL';

        ok $v->required('time3')->time,         'time3 валидация';
        ok ! $v->has_error('time3'),            'time3 ошибки нет';
        is $v->param('time3'), '11:33:44',      'time3 дата и время РФ';

        ok $v->required('time4')->time,         'time4 валидация';
        ok ! $v->has_error('time4'),            'time4 ошибки нет';
        is $v->param('time4'), '11:33:44',      'time4 дата и время SQL';

        ok $v->required('time5')->time,         'time5 валидация';
        ok ! $v->has_error('time5'),            'time5 ошибки нет';
        is $v->param('time5'), '11:33:44',      'time5 время';

        ok $v->required('time6')->time,         'time6 валидация';
        ok ! $v->has_error('time6'),            'time6 ошибки нет';
        is $v->param('time6'), '11:33:44',      'time6 время с пробелами';

        ok $v->required('time7')->time,         'time7 валидация';
        ok ! $v->has_error('time7'),            'time7 ошибки нет';
        is $v->param('time7'), '11:33:00',      'time7 время без секунд';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/time", form => {
        time0   => '',
        time1   => '29.02.2012',
        time2   => '2012-02-29',
        time3   => '29.02.2012 11:33:44',
        time4   => '2012-02-29 11:33:44',
        time5   => '11:33:44',
        time6   => '  11:33:44 ',
        time7   => '2.3.2012 11:33',
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

