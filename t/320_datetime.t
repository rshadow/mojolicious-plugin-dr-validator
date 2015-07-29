#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 40;
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

note 'datetime';
{
    $t->app->routes->post("/test/datetime")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        my $now = DateTime->now;
        my $tz  = strftime '%z', localtime;

        ok $v->required('datetime0')->datetime,     'datetime0 валидация';
        ok $v->has_error('datetime0'),              'datetime0 ошибка';
        is $v->param('datetime0'), undef,           'datetime0 пустая строка';

        my $datetime1 = DateTime->new(
            year        => 2012,
            month       => 02,
            day         => 29,
            time_zone   => $tz,
        )->strftime('%F %T %z');

        ok $v->required('datetime1')->datetime,     'datetime1 валидация';
        ok ! $v->has_error('datetime1'),            'datetime1 ошибки нет';
        is $v->param('datetime1'), "$datetime1",    'datetime1 дата РФ';

        ok $v->required('datetime2')->datetime,     'datetime2 валидация';
        ok ! $v->has_error('datetime2'),            'datetime2 ошибки нет';
        is $v->param('datetime2'), "$datetime1",    'datetime2 дата SQL';

        my $datetime3 = DateTime->new(
            year        => 2012,
            month       => 2,
            day         => 29,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => $tz
        )->strftime('%F %T %z');

        ok $v->required('datetime3')->datetime,     'datetime3 валидация';
        ok ! $v->has_error('datetime3'),            'datetime3 ошибки нет';
        is $v->param('datetime3'), "$datetime3",    'datetime3 дата и время РФ';

        ok $v->required('datetime4')->datetime,     'datetime4 валидация';
        ok ! $v->has_error('datetime4'),            'datetime4 ошибки нет';
        is $v->param('datetime4'), "$datetime3",    'datetime4 дата и время SQL';

        ok $v->required('datetime5')->datetime,     'datetime5 валидация';
        ok ! $v->has_error('datetime5'),            'datetime5 ошибки нет';
        is $v->param('datetime5'), "$datetime3",    'datetime5 с пробелами';

        my $datetime6 = DateTime->new(
            year        => $now->year,
            month       => $now->month,
            day         => $now->day,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => $tz,
        )->strftime('%F %T %z');

        ok $v->required('datetime6')->datetime,     'datetime6 валидация';
        ok ! $v->has_error('datetime6'),            'datetime6 ошибки нет';
        is $v->param('datetime6'), "$datetime6",    'datetime6 только время';

        my $datetime7 = DateTime->new(
            year        => 2012,
            month       => 2,
            day         => 29,
            hour        => 11,
            minute      => 33,
            second      => 44,
            time_zone   => '+0300'
        )->strftime('%F %T %z');

        ok $v->required('datetime7')->datetime,     'datetime7 валидация';
        ok ! $v->has_error('datetime7'),            'datetime7 ошибки нет';
        is $v->param('datetime7'), "$datetime7",    'datetime7 с поясом РФ';

        ok $v->required('datetime8')->datetime,     'datetime8 валидация';
        ok ! $v->has_error('datetime8'),            'datetime8 ошибки нет';
        is $v->param('datetime8'), "$datetime7",    'datetime8 с поясом SQL';

        my $datetime9 = DateTime->new(
            year        => 2013,
            month       => 3,
            day         => 27,
            hour        => 14,
            minute      => 55,
            second      => 00,
            time_zone   => '+0300'
        )->strftime('%F %T %z');

        ok $v->required('datetime9')->datetime,     'datetime9 валидация';
        ok ! $v->has_error('datetime9'),            'datetime9 ошибки нет';
        is $v->param('datetime9'), "$datetime9",    'datetime9 за браузера';

        my $datetime10 = DateTime->new(
            year        => 2012,
            month       => 3,
            day         => 2,
            hour        => 11,
            minute      => 33,
            second      => 00,
            time_zone   => $tz
        )->strftime('%F %T %z');

        ok $v->required('datetime10')->datetime,    'datetime10 валидация';
        ok ! $v->has_error('datetime10'),           'datetime10 ошибки нет';
        is $v->param('datetime10'), "$datetime10",  'datetime10 без секунд';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/datetime", form => {
        datetime0   => '',
        datetime1   => '29.02.2012',
        datetime2   => '2012-02-29',
        datetime3   => '29.02.2012 11:33:44',
        datetime4   => '2012-02-29 11:33:44',
        datetime5   => '   2012-02-29   11:33:44  ',
        datetime6   => '11:33:44',
        datetime7   => '29.02.2012 11:33:44 +0300',
        datetime8   => '2012-02-29 11:33:44 +0300',
        datetime9   => 'Wed Mar 27 2013 15:55:00 GMT+0400 (MSK)',
        datetime10  => '2.3.2012 11:33',
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

