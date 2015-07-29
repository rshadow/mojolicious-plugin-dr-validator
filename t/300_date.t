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

note 'date';
{
    $t->app->routes->post("/test/date")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        my $now = DateTime->now;

        ok $v->required('date0')->date,         'date0 валидация';
        ok $v->has_error('date0'),              'date0 ошибка';
        is $v->param('date0'), undef,           'date0 пустая строка';

        ok $v->required('date1')->date,         'date1 валидация';
        ok ! $v->has_error('date1'),            'date1 ошибки нет';
        is $v->param('date1'), '2012-02-29',    'date1 дата РФ';

        ok $v->required('date2')->date,         'date2 валидация';
        ok ! $v->has_error('date2'),            'date2 ошибки нет';
        is $v->param('date2'), '2012-02-29',    'date2 дата SQL';

        ok $v->required('date3')->date,         'date3 валидация';
        ok ! $v->has_error('date3'),            'date3 ошибки нет';
        is $v->param('date3'), '2012-02-29',    'date3 дата и время РФ';

        ok $v->required('date4')->date,         'date4 валидация';
        ok ! $v->has_error('date4'),            'date4 ошибки нет';
        is $v->param('date4'), '2012-02-29',    'date4 дата и время SQL';

        my $default = DateTime->new(
            year        => $now->year,
            month       => $now->month,
            day         => $now->day,
            time_zone   => 'local',
        )->strftime('%F');

        ok $v->required('date5')->date,         'date5 валидация';
        ok ! $v->has_error('date5'),            'date5 ошибки нет';
        is $v->param('date5'), "$default",      'date5 время';

        ok $v->required('date6')->date,         'date6 валидация';
        ok ! $v->has_error('date6'),            'date6 ошибки нет';
        is $v->param('date6'), '2012-02-29',    'date6 дата с пробелами';

        ok $v->required('date7')->date,         'date7 валидация';
        ok ! $v->has_error('date7'),            'date7 ошибки нет';
        is $v->param('date7'), '2012-03-02',    'date7 время без секунд';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/date", form => {
        date0   => '',
        date1   => '29.02.2012',
        date2   => '2012-02-29',
        date3   => '29.02.2012 11:33:44',
        date4   => '2012-02-29 11:33:44',
        date5   => '11:33:44',
        date6   => '   29.02.2012  ',
        date7   => '2.3.2012 11:33',
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

