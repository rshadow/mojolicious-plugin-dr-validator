use utf8;
use strict;
use warnings;

package Mojolicious::Plugin::DR::Validator;
use Mojo::Base 'Mojolicious::Plugin';

use DR::I18n;
use DR::Money;
use Mail::RFC822::Address;
use DateTime;
use DateTime::Format::DateParse;
use POSIX                   qw(strftime);

use Mojolicious::Plugin::DR::Validator::Address;

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::DR::Validator - плагин валидации. Добавляет множество
проверок помимо базовых из Mojolicious::Validator.

=head1 DESCRIPTION

=head2 Методы валидатора

=over

=item int

Проверяет и извлекает целое число.

=item numeric

Проверяет и извлекает дробное число.

=item money

Проверяет на число с дробнойчастью в сотых долях. Возвращает объект DR::Money.

=item percent

Проверяет на число в диапазоне от 0 до 100.

=item str

Простой тип без особых проверок. Полученные данные очищаются от пробелов в
начале и в конце строки.

=item text

Простой тип без особых проверок. В отличие от L<str> пробелы не убираются.

=item uuid

Проверяет на UUID значения которого могут быть символами [0-9a-fA-F].

=item date

Парсит дату и возвращает ее в SQL формате. Время выставляется в 00:00:00.
Формат можно изменить параметром конфигурации date.

=item time

Парсит время и возвращает дату в SQL формате. Число будет текущее.
Формат можно изменить параметром конфигурации time.

=item datetime

Парсит дату и возвращает ее в SQL формате.
Формат можно изменить параметром конфигурации datetime.

=item bool

Проверяет на булевое значение. Истинные значения должны быть одним из:
1, yes, true, ok.

=item email

Проверяет валидность почтового адреса используя Mail::RFC822::Address.

=item url

Проверяет и возвращает Mojo::URL.

=item phone

Проверяет телефон в формате +7...

=item address

Парсит и проверяет наличие адреса.
Если плагин подключен с подписью в параметре конфигурации address_secret, то
проверяет ее.
Возвратит объект Mojolicious::Plugin::DR::Validator::Address.

=item lon

Проверяет на число и диапазон от -180 до 180.

=item lat

Проверяет на число и диапазон от -90 до 90.

=item inn

Проверяет формат ввода и контрольные суммы ИНН.

=item kpp

Проверяет формат ввода КПП.

=back

=head2 Для роутов ->over(...) добаляются следующие валидаторы

=over

=item int

=item numeric

=item phone

=back

=head2 Дополнительные валидаторы

=item range

Проверяет занчение на диапазон

=item min

Проверяет что значение не меньше заданного

=item max

Проверяет что значение не больше заданного

=back

=head2 Дополнительные функции

=over

=item checked

Чекбоксы не передают значения если не включены. Поэтому required будет всегда
выводить ошибку если чекбокс не выбран. А optional будет игнорировать проверку
содержимого. Чтобы этого не происходило используйте данный метод.

=back

=cut

=head1 EXAMPLE

    # Пример использования валидатора
    my $validation = $c->validation;
    $validation->optional('id')->int;

    # Чекбоксы
    $validation->checked('box')->bool;

    # Пример использования в роуте
    $r->get('user/:id')->over(int => 'id')->to(...);

=cut


# Вспомогательные функции


# Убирает лишние пробелы
sub _trim {
    my ($str) = @_;
    return unless defined $str;
    s/^\s+//, s/\s+$// for $str;
    return $str;
}

# Парсинг даты
sub _parse_date {
    my ($str) = @_;

    return unless defined $str;
    s{^\s+}{}, s{\s+$}{} for $str;
    return unless length $str;

    my $dt;

    if( $str =~ m{^\d+$} ) {
        # Создадим из числа
        $dt = DateTime->from_epoch( epoch => int $str );
    } elsif( $str =~ m{^[\+\-]\d+$} ) {
        # Относительное время
        my $minutes = int $str;
        $dt = DateTime->now();
        $dt->add(minutes => $minutes);
        ;
    } else {
        # Фикс для парсинга дополнительного формата даты
        $str =~ s{^(\d{1,2})\.(\d{1,2})\.(\d{4})(.*)$}{$3-$2-$1$4};
        # Если выглядит как время то добавляем дату
        $str = DateTime->now->strftime('%F ') . $str if $str =~ m{^\s*\d{2}:};

        # Парсинг даты
        $dt = eval { DateTime::Format::DateParse->parse_datetime( $str ); };
        return if !$dt or $@;
    }

    # Приведем к локальной
    $dt->set_time_zone( strftime '%z', localtime );

    return $dt;
}

# Парсинг адреса
sub _parse_address {
    return Mojolicious::Plugin::DR::Validator::Address->parse( $_[0] );
}

sub _parse_url {
    return Mojo::URL->new( $_[0] );
}


# Валидаторы


# Целые числа
sub _int {
    return __('Значение не задано')     unless defined $_[0];
    return __('Неверный формат')        unless $_[0] =~ m{^[-+]?\d+$};
    return 0;
}

# Дробные числа
sub _numeric {
    return __('Значение не задано')     unless defined $_[0];
    return __('Неверный формат')        unless $_[0] =~ m{^[-+]?\d+(?:\.\d*)?$};
    return 0;
}

# Деньги
sub _money {
    return __('Значение не задано')     unless defined $_[0];

    my $numeric = _numeric $_[0];
    return $numeric if $numeric;

    return __('Неверный дробная часть')
        if $_[0] =~ m{\.} && $_[0] !~ m{\.\d{0,2}$};
    return 0;
}

# Проценты от 0 до 100
sub _percent {
    return __('Значение не задано')     unless defined $_[0];

    my $numeric = _numeric $_[0];
    return $numeric if $numeric;

    return __('Значение должно быть больше 0')      unless $_[0] >= 0;
    return __('Значение должно быть меньше 100')    unless $_[0] <= 100;
    return 0;
}

# Строка
sub _str {
    return __('Значение не задано')     unless defined $_[0];
    return 0;
}

# Строка без изменений
sub _text {
    return _str $_[0];
}

# UUID
sub _uuid {
    return 0 unless defined $_[0];
    return __('Неверный формат')
        unless $_[0] =~ m{^[0-9a-f]{8}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{4}-?[0-9a-f]{12}$}i;
    return 0;
}

# Дата
sub _date {
    return __('Неверный формат')        unless defined $_[0];
    return 0;
}

# Время
sub _time {
    return __('Неверный формат')        unless defined $_[0];
    return 0;
}

# Дата + Время
sub _datetime {
    return __('Неверный формат')        unless defined $_[0];
    return 0;
}

# Истина/Ложь
sub _bool {
    # Особенность форм в том что они не передают выключенные чекбоксы
    return 0 unless defined $_[0];
    return __('Неверный формат')
        unless $_[0] =~ m{^(?:1|0|yes|no|true|false|ok|fail|\s*)$}i;
    return 0;
}

# Почта
sub _email {
    return __('Значение не задано')     unless defined $_[0];
    return __('Адрес задан неверно')
        unless Mail::RFC822::Address::valid( $_[0] );
    return 0;
}

# URL
sub _url {
    return __('Значение не задано')     unless defined $_[0];
    return __('Протокол не задан')      unless $_[0]->scheme;
    return __('Адрес не задан')         unless $_[0]->host;
    return 0;
}

# Телефон
sub _phone {
    return __('Значение не задано')     unless defined $_[0];
    return __('Номер должен быть в формате +7...')
        unless $_[0] =~ m{^\+\d};
    return __('Номер должен быть не менее 11 цифр')
        unless $_[0] =~ m{^\+\d{11,16}(?:[pw]\d+)?$};
    return 0;
}

# Адрес
sub _address {
    return __('Значение не задано')     unless defined $_[0];
    return __('Неверный формат')        unless ref $_[0];
    return __('Неверный формат')        unless defined $_[0]->address;
    return __('Неверный формат')        unless length  $_[0]->address;

    my $lon = _lon( $_[0]->lon );
    return $lon if $lon;

    my $lat = _lat( $_[0]->lat );
    return $lat if $lat;

    return __('Неизвестный источник')   unless $_[0]->check( $_[1] );
    return 0;
}

# Долгота
sub _lon {
    return __('Значение не задано')     unless defined $_[0];

    my $numeric = _numeric $_[0];
    return $numeric if $numeric;

    return __('Значение должно быть не менее -180°')    unless $_[0] >= -180;
    return __('Значение должно быть не более 180°')     unless $_[0] <= 180;
    return 0;
}

# Широта
sub _lat {
    return __('Значение не задано')     unless defined $_[0];

    my $numeric = _numeric $_[0];
    return $numeric if $numeric;

    return __('Значение должно быть не менее -90°')     unless $_[0] >= -90;
    return __('Значение должно быть не более 90°')      unless $_[0] <= 90;
    return 0;
}

# Идентификационный номер налогоплательщика (ИНН)
sub _inn {
    return __('Значение не задано')     unless defined $_[0];
    return __('Неверный формат')        unless $_[0] =~ m{^(?:\d{10}|\d{12})$};

    my @str = split '', $_[0];
    if( @str == 10 ) {
        return __('Ошибка контрольной суммы')
            unless $str[9] eq
                (((
                    2 * $str[0] + 4 * $str[1] + 10 * $str[2] + 3 * $str[3] +
                    5 * $str[4] + 9 * $str[5] + 4  * $str[6] + 6 * $str[7] +
                    8 * $str[8]
                ) % 11 ) % 10);
        return 0;
    } elsif( @str == 12 ) {
        return
        return __('Ошибка контрольной суммы')
            unless $str[10] eq
                (((
                    7 * $str[0] + 2 * $str[1] + 4 * $str[2] + 10 * $str[3] +
                    3 * $str[4] + 5 * $str[5] + 9 * $str[6] + 4  * $str[7] +
                    6 * $str[8] + 8 * $str[9]
                ) % 11 ) % 10)
                && $str[11] eq
                (((
                    3  * $str[0] + 7 * $str[1] + 2 * $str[2] + 4 * $str[3] +
                    10 * $str[4] + 3 * $str[5] + 5 * $str[6] + 9 * $str[7] +
                    4  * $str[8] + 6 * $str[9] + 8 * $str[10]
                ) % 11 ) % 10);
        return 0;
    }
    return __('Должно быть 10 или 12 цифр');
}

# Код причины постановки на учет (КПП)
sub _kpp {
    return __('Значение не задано')     unless defined $_[0];
    return __('Неверный формат')        unless $_[0] =~ m{^\d{9}$};
    return 0;
}

# Значение не меньше
sub _min {
    my ($value, $min) = @_;

    my $numeric = _numeric $value;
    return $numeric if $numeric;

    return sprintf __("Значение не должно быть меньше %s"), $min
        unless $value >= $min;
    return 0;
}

# Значение не больше
sub _max {
    my ($value, $max) = @_;

    my $numeric = _numeric $value;
    return $numeric if $numeric;

    return sprintf __("Значение не должно быть больше %s"), $max
        unless $value <= $max;
    return 0;
}

# Диапазон значений
sub _range {
    my ($value, $minimum, $maximum) = @_;

    my $min = _min $value => $minimum;
    return $min if $min;

    my $max = _max $value => $maximum;
    return $max if $max;

    return 0;
}


# Регистрация плагина


sub register {
    my ($self, $app, $conf) = @_;

    # Конфигурация
    $conf ||= {};
    # Формат дат и времени по умолчанию
    $conf->{date}           //= '%F';
    $conf->{time}           //= '%T';
    $conf->{datetime}       //= '%F %T %z';
    # Подпись адресов
    $conf->{address_secret} //= '';


    # Валидаторы

    $app->validator->add_check(int => sub {
        my ($validation, $name, $value) = @_;
        ($value) = $value =~ m{([-+]?\d+)};
        my $result = _int $value;
        $validation->output->{$name} = 0 + $value unless $result;
        return $result;
    });

    $app->validator->add_check(numeric => sub {
        my ($validation, $name, $value) = @_;
        ($value) = $value =~ m{([-+]?\d+(?:\.\d*)?)};
        my $result = _numeric $value;
        $validation->output->{$name} = 0.0 + $value unless $result;
        return $result;
    });

    $app->validator->add_check(money => sub {
        my ($validation, $name, $value) = @_;
        ($value) = $value =~ m{([-+]?\d+(?:\.\d*)?)};
        my $result = _money $value;
        $validation->output->{$name} = Money($value) unless $result;
        return $result;
    });

    $app->validator->add_check(percent => sub {
        my ($validation, $name, $value) = @_;
        ($value) = $value =~ m{([-+]?\d+(?:\.\d*)?)};
        my $result = _percent $value;
        $validation->output->{$name} = 0.0 + $value unless $result;
        return $result;
    });

    $app->validator->add_check(str => sub {
        my ($validation, $name, $value) = @_;
        $value = _trim $value;
        my $result = _str $value;
        $validation->output->{$name} = $value;
        return $result;
    });

    $app->validator->add_check(text => sub {
        my ($validation, $name, $value) = @_;
        my $result = _text $value;
        return $result;
    });

    $app->validator->add_check(uuid => sub {
        my ($validation, $name, $value) = @_;
        $value = _trim $value;
        my $result = _uuid $value;
        $validation->output->{$name} = lc $value;
        return $result;
    });

    $app->validator->add_check(date => sub {
        my ($validation, $name, $value) = @_;
        $value = _parse_date _trim $value;
        my $result = _date $value;
        $validation->output->{$name} = $value->strftime( $conf->{date} )
            unless $result;
        return $result;
    });

    $app->validator->add_check(time => sub {
        my ($validation, $name, $value) = @_;
        $value = _parse_date _trim $value;
        my $result = _time $value;
        $validation->output->{$name} = $value->strftime( $conf->{time} )
            unless $result;
        return $result;
    });

    $app->validator->add_check(datetime => sub {
        my ($validation, $name, $value) = @_;
        $value = _parse_date _trim $value;
        my $result = _datetime $value;
        $validation->output->{$name} = $value->strftime( $conf->{datetime} )
            unless $result;
        return $result;
    });

    $app->validator->add_check(bool => sub {
        my ($validation, $name, $value) = @_;
        $value = _trim $value;
        my $result = _bool $value;
        unless( $result ) {
            if( defined $value ) {
                ($validation->output->{$name}) =
                    $value =~ m{^(?:1|yes|true|ok)$}i ? 1 : 0
            } else {
                $validation->output->{$name} = 0;
            }
        }
        return $result;
    });

    $app->validator->add_check(email => sub {
        my ($validation, $name, $value) = @_;
        $value = _trim $value;
        my $result = _email $value;
        $validation->output->{$name} = $value unless $result;
        return $result;
    });

    $app->validator->add_check(url => sub {
        my ($validation, $name, $value) = @_;
        $value = _parse_url _trim $value;
        my $result = _url $value;
        $validation->output->{$name} = $value unless $result;
        return $result;
    });

    $app->validator->add_check(phone => sub {
        my ($validation, $name, $value) = @_;
        s{[.,]}{w}g, s{[^0-9pw]}{}g, s{w{2,}}{w}g, s{p{2,}}{p}g, s{^}{+}
            for $value;
        my $result = _phone $value;
        $validation->output->{$name} = $value unless $result;
        return $result;
    });

    $app->validator->add_check(address => sub {
        my ($validation, $name, $value) = @_;
        $value = _parse_address $value;
        my $result = _address $value => $conf->{address_secret};
        $validation->output->{$name} = $value unless $result;
        return $result;
    });

    $app->validator->add_check(lon => sub {
        my ($validation, $name, $value) = @_;
        $value = _trim $value;
        my $result = _lon $value;
        $validation->output->{$name} = $value unless $result;
        return $result;
    });

    $app->validator->add_check(lat => sub {
        my ($validation, $name, $value) = @_;
        $value = _trim $value;
        my $result = _lat $value;
        $validation->output->{$name} = $value unless $result;
        return $result;
    });

    $app->validator->add_check(inn => sub {
        my ($validation, $name, $value) = @_;
        $value = _trim $value;
        my $result = _inn $value;
        $validation->output->{$name} = $value unless $result;
        return $result;
    });

    $app->validator->add_check(kpp => sub {
        my ($validation, $name, $value) = @_;
        $value = _trim $value;
        my $result = _kpp $value;
        $validation->output->{$name} = $value unless $result;
        return $result;
    });

    $app->validator->add_check(range => sub {
        my ($validation, $name, $value, $min, $max) = @_;
        return _range $value, $min, $max;
    });

    $app->validator->add_check(min => sub {
        my ($validation, $name, $value, $min) = @_;
        return _min $value, $min;
    });

    $app->validator->add_check(max => sub {
        my ($validation, $name, $value, $max) = @_;
        return _max $value, $max;
    });


    # Выражения для роутов


    $app->routes->add_condition(int => sub {
        my ($r, $c, $captures, $pattern) = @_;
        $pattern = [ $pattern ] unless ref $pattern eq 'ARRAY';
        for my $name (@$pattern) {
            my ($value) = $captures->{$name} =~ m{([-+]?\d+)};
            return 0 if _int $value;
        }
        return 1;
    });

    $app->routes->add_condition(numeric => sub {
        my ($r, $c, $captures, $pattern) = @_;
        $pattern = [ $pattern ] unless ref $pattern eq 'ARRAY';
        for my $name (@$pattern) {
            my ($value) = $captures->{$name} =~ m{([-+]?\d+(?:\.\d*)?)};
            return 0 if _numeric $value;
        }
        return 1;
    });

    $app->routes->add_condition(phone => sub {
        my ($r, $c, $captures, $pattern) = @_;
        $pattern = [ $pattern ] unless ref $pattern eq 'ARRAY';
        for my $name (@$pattern) {
            my $value = _trim $captures->{$name};
            return 0 if _phone $value;
        }
        return 1;
    });


    # Хелперы для простого использования


    $app->helper(v_param => sub{
        my ($self, @opts) = @_;
        return  $self->validation->param(@opts);
    });

    $app->helper(v_params => sub{
        my ($self) = @_;

        my $output = $self->validation->output;
        for my $name ( keys %{ $self->validation->input } ) {
            next if $name eq 'csrf_token';
            next if exists $output->{ $name };
            $output->{ $name } = undef;
        }

        return $output;
    });

    $app->helper(v_sort => sub{
        my ($self, @fields) = @_;

        my $v = $self->validation;

        # Проверим поля
        $v->optional('page')->int->min(1);
        $v->optional('oby')->int->range(0, $#fields);
        $v->optional('ods')->like(qr{^(?:asc|desc)$}i);
        $v->optional('rws')->int->range(1, 200);

        # Преобразуем выходные значения и установим дефолты
        $v->output->{page}  //= 1;
        $v->output->{oby}   = $fields[ $v->param('oby')    // 0 ];
        $v->output->{ods}   = uc $v->param('ods')          // 'ASC';
        $v->output->{rws}   //= 20;

        return $self->v_params;
    });


    # Хак для работы валидатора с чекбоксами


    {
        warn 'Функция checked уже определена'
            if Mojolicious::Validator::Validation->can('checked');

        no warnings 'once';
        *Mojolicious::Validator::Validation::checked = sub {
            my ($self, $name) = @_;

            my $input = $self->input->{$name};
            $self->output->{$name} = $input;

            return $self->topic($name);
        };
    }
}

1;

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 All rights reserved. If You want to use the code You
 MUST have permissions from Dmitry E. Oboukhov AND
 Roman V Nikolaev.

=cut
