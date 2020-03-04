use v5.14;
use warnings;

package Jasonify;
# ABSTRACT: Just Another Serialized Object Notation library.

=head1 SYNOPSIS

 use Jasonify;

 my $jasonify = Jasonify->new( ... );    # See OPTIONS below
 $jasonify = $jasonify->set( ... );      # See OPTIONS below
 print $jasonify->encode( ... );         # ...

 # Or

 Jasonify->set( ... );                   # See OPTIONS below
 print Jasonify->encode( ... );          # ...

=head1 DESCRIPTION

C<Jasonify> is very similar to L<JSON>,
except that it's easier to use, has better defaults and options.

=cut

use Carp                ();    #qw( carp );
use Datify    v0.20.064 ();
use LooksLike v0.20.060 ();    #qw( number representation );
use Scalar::Util        ();    #qw( blessed reftype );
use String::Tools       ();    #qw( subst );

use parent 'Datify';


=method C<< new( ... ) >>

Create a C<Jasonify> object with the following options.

See L</OPTIONS> for a description of the options and their default values.

=cut


### Accessor ###

=method exists( name, name, ... )

Determine if values exists for one or more settings.

Can be called as a class method or an object method.

=cut

=method C<get( name, name, ... )>

Get one or more existing values for one or more settings.
If passed no names, returns all parameters and values.

Can be called as a class method or an object method.

=cut


### Setter ###

=method C<< set( name => value, name => value, ... ) >>

Change the L</OPTIONS> settings.
When called as a class method, changes default options.
When called as an object method, changes the settings and returns a
new object.

See L</OPTIONS> for a description of the options and their default values.

B<NOTE:> When called as a object method, this returns a new instance
with the values set, so you will need to capture the return if you'd like to
persist the change:

 $jasonify = $jasonify->set( ... );

=cut


=option Encode options

=over

=item I<list_sep> => B<', '>

=item I<beautify> => B<undef>

=back

=cut

__PACKAGE__->set(
    # Varify/Encode options
    #name     => '',
    #assign   => undef,
    #list     => undef,
    list_sep => ', ',
    beautify => undef,
);


=option Undefify options

=over

=item I<null> => B<'null'>

How C<undef> is encoded.

=back

=cut

__PACKAGE__->set(
    # Undefify options
    null  => 'null',
);


=option Booleanify options

=over

=item I<false> => B<'false'>

=item I<true>  => B<'true'>

How the boolean values are encoded.

=back

=cut

__PACKAGE__->set(
    # Booleanify options
    false => 'false',
    true  => 'true',
);


=option Stringify options

=over

=item I<quote> => B<'"'>

Use double-quoted strings in all cases.

=item I<longstr> => B<-1>

All strings are to be considered long, and encoded accordingly.

=item I<econde2> => { ... }

=over

=item I<[[:cntrl:]]> => sprintf( '\\u00%02x', ord($_) )

=item I<"\x{2028}", "\x{2029}"> => sprintf( '\\u%04x', ord($_) )

=item I<"\b"> => B<'\b'>

=item I<"\t"> => B<'\t'>

=item I<"\n"> => B<'\n'>

=item I<"\r"> => B<'\r'>

=item I<'"'>  => B<'\"'>

=item I<'\\'> => B<'\\\\'>

=item I<byte> => B<'\\u00%02x'>

=item I<utf>  => B<16>

=item I<wide> => B<'\\u%04x'>

=back

Special characters, and how they are encoded.

=back

=cut

__PACKAGE__->set(
    # Stringify options
    quote  => '"',
    #quote1 => undef,
    quote2 => '"',
    #q1     => undef,
    #q2     => undef,
    #sigils => undef,
    longstr => -1,
    #encode1 => undef,
    encode2 => {
        map( { $_ => sprintf( '\\u%04x', $_ ) }
            0x00 .. 0x1f, 0x7f,    # Control characters (C0)
            0x80 .. 0x9f,          # Control characters (C1)
            0x2028, 0x2029,        # Characters not allowed by Javascript
        ),
        # Special cases
        map( { ord( eval qq!"$_"! ) => $_ } qw( \b \t \n \r \" \\\\ ) ),
        utf  => 16,
        byte => '\\u00%02x',
        wide => '\\u%04x',
    },
    #qpairs  => undef,
    #qquotes => undef,
);


=option Numify options

=over

=item I<infinite>  => B<Infinifty>,

=item I<-infinite> => B<-Infinifty>,

=item I<nonnumber> => B<NaN>,

How to encode the values for infinity, negative infinity, and not-a-number.

=back

=cut

__PACKAGE__->set(
    # Numify options
    infinite  => 'Infinity',
    -infinite => '-Infinity',
    nonnumber => 'NaN',
    #num_sep  => undef,
);


=option Lvalueify options

=over

=item I<lvalue> => B<'$lvalue'>

Encode C<lvalue>s as simple strings.

=back

=cut

__PACKAGE__->set(
    # Lvalueify options
    lvalue    => '$lvalue',
);


=option Vstringify options

=over

=item I<vformat> => B<'\\u%0*v4x'>

=item I<vsep>    => B<'\\u'>

Encode vstrings as a series of 4-character hex digits separated by C<'\u'>.

=back

=cut

__PACKAGE__->set(
    # Vstringify options
    vformat => '"\\u%0*v4x"',
    vsep    => '\\u',
);


#=option Regexpify options
#
#=over
#
#=item ...
#
#=back
#
#=cut
#
#__PACKAGE__->set(
#    # Regexpify options
#    #quote3  => undef,
#    #q3      => undef,
#    #encode3 => undef,
#);


=option Arraryify options

=over

=item I<array_ref> => B<'[$_]'>

A reference to an C<ARRAY> is encoded in this manner.

=back

=cut

__PACKAGE__->set(
    # Arrayify options
    array_ref => '[$_]',
);


=option Hashify options

=over

=item I<hash_ref>         => B<'{$_}'>

A reference to a C<HASH> is encoded in this manner.

=item I<pair>             => B<'$key : $value'>

Pairs are encoded in this manner.

=item I<keysort>          => B<\&Datify::keysort>

The function used to sort entries in a hash.

=item I<keyfilter>        => B<undef>

How to filter items in a C<HASH>.

=item I<keyfilterdefault> => B<1>

How to interpret filtered items in a C<HASH>.

=back

=cut

__PACKAGE__->set(
    # Hashify options
    hash_ref         => '{$_}',
    pair             => '$key : $value',
    keymap           => \&Jasonify::keymap,
    keysort          => \&Datify::keysort,
    keyfilter        => undef,
    keyfilterdefault => 1,
    #keywords         => undef,
);


=option Objectify options

=over

=item I<json_method> => B<'TO_JSON'>

The method to search for to see if an object has a specific representation
for itself.

=item I<object>      => B<'$data'>

Objects are decomposed using this.
If you wanted to decompose objects with the class name in addition to
the internal representation of the data, then you may want to use
C<'{$class_str : $data}'>.

=item I<overloads>   => B<[ '""', '0+' ]>

If objects have overloaded these, use them to decompose the object.

=item I<tag>         => B<undef>

To enable tag output, set this to C<'($class_str)$data'>.

=item I<tag_method>  => B<'FREEZE'>

The method to search for to see if an object should be represented in the
tag format.

=back

=cut

__PACKAGE__->set(
    # Objectify options
    json_method => 'TO_JSON',
    object      => '$data',
    #object      => '{$class_str : $data}',
    overloads   => [qw( "" 0+ )],
    tag         => undef,
    #tag         => '($class_str)$data',
    tag_method  => 'FREEZE',
);


=option Ioify options

=over

=item I<io> => B<'null'>

How IO objects will be decomposed.

=back

=cut

__PACKAGE__->set(
    # Ioify options
    io => 'null',
);


=option Codeify options

=over

=item I<code> => B<'null'>

How C<CODE> references will be decomposed.

=back

=cut

__PACKAGE__->set(
    # Codeify options
    code     => 'null',
    #codename => undef,
    #body     => undef,
);


=option Refify options

=over

=item I<reference> => B<'$_'>

References will be ignored, and the actual value will be encoded.

=item I<dereference> => B<'$referent$place'>

When referring to a location in the reference, decompose with this.

=back

=cut

__PACKAGE__->set(
    # Refify options
    reference   => '$_',
    dereference => '$referent$place',
    #nested      => undef,
);


=option Formatify options

=over

=item I<format> => B<'null'>

How a C<FORMAT> will be encoded.

=back

=cut

__PACKAGE__->set(
    # Formatify options
    format => 'null',
);


=method C<booleanify( value )>

Returns the string that represents the C<true> or C<false> interpretation
of C<value>.
If C<value> is a scalar reference, calls itself with C<value> dereferenced.
Will return the value for C<undefify> if C<value> is not defined.

=cut

# Override Datify::booleanify() for SCALAR refs
sub booleanify {
    my $self = &Datify::self;
    local $_ = shift if @_;
    return $self->undefify unless defined;
    return $self->booleanify($$_) if 'SCALAR' eq ref;
    return $_ ? $Jasonify::Boolean::true : $Jasonify::Boolean::false;
}


=method C<keyify( value )>

Returns value as a key.
NOTE: Numbers are always quoted when used as keys.

=cut

# Override Datify::keyify() to appropriately stringify all keys
sub keyify {
    my $self = &Datify::self;
    local $_ = shift if @_;

    my $blessed = Scalar::Util::blessed($_);
    return defined($blessed) && $blessed->isa("Jasonify::Literal")
        ? $_
        : $self->stringify($_);
}

# Override Datify::hashkeyvals to handle Jasonify::_key elements
sub hashkeyvals {
    my $self = shift;
    my $hash = shift;

    return map {
        my $blessed = Scalar::Util::blessed($_);
        if ( defined($blessed) ) {
            Carp::croak("Cannot handle $blessed")
                unless $blessed->isa("Jasonify::_key");
            ( $_->string() => $hash->{ $_->key() } );
        } else {
            ( $_ => $hash->{$_} );
        }
    } $self->hashkeys($hash);
}

# Implement a keymap for unusual numbers
sub keymap {
    my $self = &Datify::self;
    local $_ = shift if @_;

    return $_ unless ( LooksLike::infinity($_) || LooksLike::nan($_) );

    my $rep = LooksLike::representation(
        $_,

        "infinity"  => [ $Jasonify::Number::inf,  Jasonify->get("infinite")  ],
        "-infinity" => [ $Jasonify::Number::ninf, Jasonify->get("-infinite") ],
        "nan"       => [ $Jasonify::Number::nan,  Jasonify->get("nonnumber") ],
    );
    # key     string         sortby
    # ======= ============== ===========
    # "inf",  '"Infinity"',  "Infinity"
    # "-inf", '"-Infinity"', "-Infinity"
    # "nan",  '"NaN"',       "NaN"
    return Jasonify::_key->new( $_, @$rep );
}

sub _objectify_via {
    my $self   = shift;
    my $object = shift;

    if ( my $method_name = shift ) {
        return $object->can($method_name);
    }
    return;
}
sub _objectify_via_tag {
    my $self   = shift;
    my $object = shift;

    my $tag_method = $self->get('tag') && $self->get('tag_method');
    return $self->_objectify_via( $object => $tag_method );
}
sub _objectify_via_json {
    my $self   = shift;
    my $object = shift;

    return $self->_objectify_via( $object => $self->get('json_method') );
}


=method C<objectify( value )>

Returns value as an object.
Goes through a series of checks to format the object appropriately:

If a handler has been defined for the object with
L</C<< add_handler( $class => \&code_ref ) >>>, then use that.
If L</tag> has been enabled, and the object has a method that corresponds
to L</tag_method>, then that is used.
If the object has a method that corresponds to L</json_method>,
then that is used.
If the object has overloaded any of
L<< /I<overloads>  => B<[ '""', '0+' ]> >>, then use that to represent
the C<$data> portion of the object.
If the object has an C<_attrkeyvals> method,
then that will be used to gather the elements of the object.
If the object has none of those things, then the object is inspected
and handled appropriately.

=cut

# Override Datify::objectify() to appropriately stringify objects
sub objectify {
    my $self   = &Datify::self;
    my $object = shift;

    return $self->scalarify($object)
        unless defined( my $class = Scalar::Util::blessed($object) );

    my $object_str = $self->get('object');

    my $data;
    if (0) {
    } elsif ( my $code = $self->_find_handler($class) ) {
        return $self->$code($object);
    } elsif ( my $tag = $self->_objectify_via_tag($object) ) {
        $object_str = $self->get('tag');
        $data = $self->arrayify( $object->$tag('JSON') );
    } elsif ( my $to_json = $self->_objectify_via_json($object) ) {
        $data = $self->scalarify( $object->$to_json() );
    } elsif ( my $method = $self->overloaded($object) ) {
        $data = $self->scalarify( $object->$method() );
    } elsif ( my $attrkeyvals = $object->can('_attrkeyvals') ) {
        # TODO: Look this up via meta-objects and such.
        $data = $self->hashify( $object->$attrkeyvals() );
    } else {
        $data = Scalar::Util::reftype $object;

        $data
            = $data eq 'ARRAY'  ? $self->arrayify(  @$object )
            : $data eq 'CODE'   ? $self->codeify(    $object )
            : $data eq 'FORMAT' ? $self->formatify(  $object )
            : $data eq 'GLOB'   ? $self->globify(    $object )
            : $data eq 'HASH'   ? $self->hashify(    $object )
            : $data eq 'IO'     ? $self->ioify(      $object )
            : $data eq 'REF'    ? $self->scalarify( $$object )
            : $data eq 'REGEXP' ? $self->regexpify(  $object )
            : $data eq 'SCALAR' ? $self->scalarify( $$object )
            :                     $self->undefify;
    }

    return String::Tools::subst(
        $object_str,
        class_str => $self->stringify($class),
        class     => $class,
        data      => $data,
    );
}


=method C<regexpify( value, delimiters )>

Simply calls out to L</stringify>.

=cut

# Override Datify::regexpify() to appropriately stringify regular expressions
sub regexpify {
    my $self = &Datify::self;
    local $_ = shift if @_;

    return $self->stringify($_);
}

# Override Datify::varify so that it throws an error
sub varify;


=method C<vstringify( value )>

A representation of the VString.
If L</vformat> is specified, as a series of four digit hex values
separated by C<'\\u'>.
If L</vformat> is false, as a regular via L</stringify>.

=cut

# Override Datify::vstringify so that it encodes a vstring as appropriate
sub vstringify {
    my $self = &Datify::self;
    local $_ = shift if @_;

    # Encode as a vstring    if vformat has     been specified
    # or as a regular string if vformat has not been specified
    return $self->get('vformat')
        ? $self->SUPER::vstringify($_)
        : $self->stringify($_);
}


sub numify {
    my $self = &Datify::self;
    local $_ = shift if @_;

    return $self->undefify unless defined;

    return
          $self->is_numeric($_) ? $_
        : LooksLike::number($_) ? LooksLike::representation(
            $_,

            "infinity"  => $Jasonify::Number::inf,
            "-infinity" => $Jasonify::Number::ninf,
            "nan"       => $Jasonify::Number::nan,
        )
        :                         $Jasonify::Number::nan;
}

=method C<scalarify( value )>

This is the method called by L</encode( value, ... )>

TODO:
Returns value as a scalar.  If value is not a reference, performs some magic
to correctly print vstrings and numbers, otherwise assumes it's a string.
If value is a reference, hands off to the correct function to create
the string.

Handles reference loops.

=cut

# Override Datify::scalarify to properly handle all of the various types
sub _scalarify {
    my $self = &Datify::self;
    local $_ = shift if @_;

    return $self->undefify unless defined $_;

    if ( defined( my $blessed = Scalar::Util::blessed($_) ) ) {
        return
              $blessed eq 'Regexp' ? $self->regexpify($_)
            :                        $self->objectify($_);
    }

    my $ref = Scalar::Util::reftype $_;
    if ( not $ref ) {
        # Handle GLOB, LVALUE, and VSTRING
        my $ref2 = ref \$_;
        return
              $ref2 eq 'GLOB'    ? $self->globify($_)
            : $ref2 eq 'LVALUE'  ? $self->lvalueify($_)
            : $ref2 eq 'VSTRING' ? $self->vstringify($_)
            : $ref2 eq 'SCALAR' && LooksLike::number($_)
                                 ? $self->numify($_)
            :                      $self->stringify($_)
            ;
    }

    return
          $ref eq 'ARRAY'   ? $self->arrayify(@$_)
        : $ref eq 'CODE'    ? $self->codeify($_)
        : $ref eq 'FORMAT'  ? $self->formatify($_)
        : $ref eq 'GLOB'    ? $self->globify($$_)
        : $ref eq 'HASH'    ? $self->hashify($_)
        : $ref eq 'IO'      ? $self->ioify($_)
        : $ref eq 'LVALUE'  ? $self->booleanify($$_)
        : $ref eq 'REF'     ? $self->refify($$_)
        : $ref eq 'REGEXP'  ? $self->regexpify($_)     # ???
        : $ref eq 'SCALAR'  ? $self->booleanify($$_)
        : $ref eq 'VSTRING' ? $self->booleanify($$_)
        :                     $self->objectify($_)     # ???
        ;
}


=method C<decode( value, ... )>

Decode one or more string representations of C<JSON>.

B<NOTE:> This method is not implemented yet,
it is a placehold for future implementations.

=cut

# TODO
sub decode;


=method C<encode( value, ... )>

Encode one or more values to C<JSON> formatted strings.

Can be called as a class or object method.

=cut

sub encode {
    my $self = &Datify::self;
    return unless @_;

    my @return = map { $self->scalarify($_) } @_;

    $self->_cache_reset();

    return @_ == 1 ? $return[0] : @return;
}


=method C<boolean( value )>

If passed a C<value>, returns the boolean for that value.
If passed no C<value>, retunrs the name of the class representing booleans.

Also aliased as C<bool( value )>.

See L</Jasonify::Boolean>.

=cut

sub boolean {
    &Datify::class;
    return @_ ? Jasonify::Boolean::bool( $_[-1] ) : 'Jasonify::Boolean';
}
*bool = \&boolean;


=method C<literal( value )>

If passed a C<value>, returns a representation of that value that,
when encoded, will be exactly that C<value>.
If passed no C<value>, returns the name of the class representing literals.

See L</Jasonify::Literal>.

=cut

sub literal {
    &Datify::class;
    return @_ ? Jasonify::Literal->new( $_[-1] ) : 'Jasonify::Literal';
}


=method C<number( value, ... )>

If passed in a single C<value>, returns a representation of that value that,
when encoded, will be exactly that C<value>.
If passed in two or more C<value>s, returns a representation of that value
when passed through to C<sprintf()>.
If passed no C<value>, returns the name of the class representing numbers.

See L</Jasonify::Number>.

=cut

sub number {
    &Datify::class;
    my $count = scalar @_;
    return
          $count >= 2 ? Jasonify::Number->formatted(@_)
        : $count == 1 ? Jasonify::Number->number(shift)
        :              'Jasonify::Number'
        ;
}


=method C<string( value )>

If passed a C<value>, returns a representation of that value that,
when encoded, will be exactly that C<value> as a string.

See L</Jasonify::Literal>.

=cut

sub string {
    &Datify::class;
    return @_ ? Jasonify::Literal->string( $_[-1] ) : 'Jasonify::Literal';
}

### Private Methods & Settings ###
### Do not use these methods & settings outside of this package,
### they are subject to change or disappear at any time.
sub _settings() { \state %SETTINGS }

__PACKAGE__->set(
    _cache_hit  => 1,   # Sets the caching to use the final representation
                        # or die if that doesn't exist
);

=head1 TODO

=over

=item *

Implement C<decode()>.

=back

=head1 SEE ALSO

L<JSON>, L<Datify>

=cut


package
    Jasonify::_key;

use parent -norequire => 'Jasonify::Literal';

use overload
    '""'  => 'string',
    'cmp' => 'compares',
    '<=>' => 'comparen',
    ;

sub new {
    my $class = &Datify::class;
    my @self  = @_;               # key, string, sortby
    return bless( \@self, $class );
}

sub key    { $_[0][ 0] }
sub string { $_[0][+1] }
sub sortby { $_[0][-1] }

sub comparen { ( $_[2] ? -1 : +1 ) * ( $_[0]->sortby <=> $_[1] ) }
sub compares { ( $_[2] ? -1 : +1 ) * ( $_[0]->sortby cmp $_[1] ) }


package
    Jasonify::Literal;

use LooksLike ();    #qw( zero );

use overload
    'bool' => 'bool',
    '""'   => 'as_string',
    ;

our $null  = bless \do { my $null  = Jasonify->get('null')  }, __PACKAGE__;
our $false = bless \do { my $false = Jasonify->get('false') }, __PACKAGE__;
our $true  = bless \do { my $true  = Jasonify->get('true')  }, __PACKAGE__;

sub Jasonify::jasonify_literalify { $_[1]->as_string }
# OR
#Jasonify->add_handler( sub { $_[1]->as_string } );

sub null()  { $null  }
sub false() { $false }
sub true()  { $true  }

sub new {
    my $class   = &Datify::class;
    my $literal = shift;
    return $null  unless defined($literal);
    return $false unless length( $literal);
    return bless \$literal, $class;
}
sub string {
    @_ = ( shift, Jasonify->stringify(@_) );
    goto &new;
}
#sub comment {
#    $_[0]->new(
#        "# " . join( "\n# ", map { split /\n/ } @_[ 1 .. $#_ ] ) . "\n" );
#}

sub as_string { ${ $_[0] } }
sub bool {
    my $literal = ${ $_[0] };
    return
           $literal ne $$null
        && $literal ne $$false
        && $literal ne '""'
        && $literal ne '"0"'
        && !LooksLike::zero($literal);
}


package
    Jasonify::Number;

use LooksLike ();    #qw( number numeric representation );

use overload
    '0+'  => 'as_num',
    'neg' => 'negate',

    '<=>' => 'comparen',
    'cmp' => 'compares',
    ;
use parent -norequire => 'Jasonify::Literal';

our ( $nan, $inf, $ninf )
    = map {
        bless \do { Jasonify->stringify($_) }, __PACKAGE__
    } Jasonify->get(qw( nonnumber infinite -infinite ));

sub Jasonify::jasonify_numberify { $_[1]->as_string }
# OR
#Jasonify->add_handler( sub { $_[1]->as_string } );

sub nan()  { $nan  }
sub inf()  { $inf  }
sub ninf() { $ninf }

my $number_regex = do {
    my $digit09 = '[0123456789]';
    my $digit19 =  '[123456789]';
    my $integer = "(?:0|$digit19+$digit09*)";
    my $decimal = "(?:\.$digit09+)";
    qr/-?$integer$decimal?(?:[Ee][+-]?$integer)?/;
};

sub comparen { ( $_[2] ? -1 : +1 ) * (    $_[0]->as_num <=> $_[1] ) }
sub compares { ( $_[2] ? -1 : +1 ) * ( ${ $_[0] }       cmp $_[1] ) }
sub as_num { eval ${ $_[0] } }
sub negate {
    my $num = ${ $_[0] };
    return
          $num eq $$nan  ? $nan
        : $num eq $$inf  ? $ninf
        : $num eq $$ninf ? $inf
        :                  $_[0]->number( $num =~ s/\A(-?)/$1 ? '' : '-'/er )
        ;
}
sub number {
    my $class = &Datify::class;
    my $num   = shift;
    Carp::croak( "Not a number ", $num )
        unless ( LooksLike::number($num) );

    return
          LooksLike::numeric($num)
        ? $num =~ /\A$number_regex\z/
            ? $class->new($num)
            : Carp::croak( "Malformed number ", $num )
        : LooksLike::representation($num);
}

sub formatted { return shift()->number( sprintf( shift(), @_ ) ) }
sub integer   { return shift()->formatted( '%d', shift() ) }
sub float     { return shift()->formatted( '%f', shift() ) }


package
    Jasonify::Boolean;

use Scalar::Util ();    #qw( blessed );

use overload
    'bool' => 'value',
    '0+'   => 'value',
    '""'   => 'as_string',

    '<=>' => 'compare',
    'cmp' => 'compare',

    '!'   => 'negate',
    ;

our $false = bless \do { my $false = 0 }, __PACKAGE__;
our $true  = bless \do { my $true  = 1 }, __PACKAGE__;

sub Jasonify::jasonify_booleanify { $_[1]->as_string }
# OR
#Jasonify->add_handler( sub { $_[1]->as_string } );

sub false() { $false }
sub true()  { $true  }

sub value { ${ $_[0] } }
sub as_string {
    ${ $_[0] } ? $Jasonify::Literal::true : $Jasonify::Literal::false;
}

sub compare { ( $_[2] ? -1 : +1 ) * ( ${ $_[0] } <=> ${ bool( $_[1] ) } ) }

sub negate { bool($_[0]) ? $false : $true }

sub bool($) {
    is_bool( $_[0] )
        ? $_[0]
        : ref( $_[0] ) eq 'SCALAR'
            ? ${ $_[0] } ? $true : $false
            :    $_[0]   ? $true : $false
        ;
}
sub is_bool($) { Scalar::Util::blessed( $_[0] ) && $_[0]->isa(__PACKAGE__) }

1;

__END__

