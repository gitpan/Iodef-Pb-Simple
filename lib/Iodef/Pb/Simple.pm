package Iodef::Pb::Simple;

use 5.008008;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.15';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Iodef::Pb::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	iodef_descriptions iodef_assessments iodef_confidence iodef_impacts iodef_impacts_first
    iodef_additional_data iodef_systems iodef_addresses iodef_events_additional_data iodef_services
    iodef_systems_additional_data iodef_normalize_restriction iodef_guid iodef_uuid iodef_malware
    iodef_bgp iodef_contacts iodef_contacts_cc iodef_normalize_purpose
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

use Iodef::Pb;
use Module::Pluggable require => 1;

my @plugins = __PACKAGE__->plugins();

sub iodef_normalize_restriction {
    my $restriction     = shift || return;
    
    if($restriction =~ /^\d$/){
        return 'private' if($restriction == RestrictionType::restriction_type_private());
        return 'public' if($restriction == RestrictionType::restriction_type_public());
        return 'need-to-know' if($restriction == RestrictionType::restriction_type_need_to_know());
        return 'default' if($restriction == RestrictionType::restriction_type_default());
        return;
    } else {
        for(lc($restriction)){
            if(/^private$/){
                $restriction = RestrictionType::restriction_type_private(),
                last;
            }
            if(/^public$/){
                $restriction = RestrictionType::restriction_type_public(),
                last;
            }
            if(/^need-to-know$/){
                $restriction = RestrictionType::restriction_type_need_to_know(),
                last;
            }
            if(/^default$/){
                $restriction = RestrictionType::restriction_type_default(),
                last;
            }   
        }
    }
    return $restriction;
}

sub iodef_normalize_purpose {
    my $thing   = shift || return;
   
    if($thing =~ /^\d$/){
        return 'other' if($thing == IncidentType::IncidentPurpose::Incident_purpose_other());
        return 'mitigation' if($thing == IncidentType::IncidentPurpose::Incident_purpose_mitigation());
        return 'traceback' if($thing == IncidentType::IncidentPurpose::Incident_purpose_traceback());
        return 'reporting' if($thing == IncidentType::IncidentPurpose::Incident_purpose_reporting());
        return;
    } else {
        for(lc($thing)){
            if(/^other/){
                $thing = IncidentType::IncidentPurpose::Incident_purpose_other(),
                last;
            }
            if(/^mitigation$/){
                $thing = IncidentType::IncidentPurpose::Incident_purpose_mitigation(),
                last;
            }
            if(/^traceback$/){
                $thing = IncidentType::IncidentPurpose::Incident_purpose_traceback(),
                last;
            }
            if(/^reporting$/){
                $thing = IncidentType::IncidentPurpose::Incident_purpose_reporting(),
                last;
            }   
        }
    }
    return $thing;
}


sub iodef_descriptions {
    my $iodef = shift;
    
    my @array;
    foreach my $i (@{$iodef->get_Incident()}){
        my $desc = $i->get_Description();
        $desc = [$desc] unless(ref($desc) eq 'ARRAY');
        push(@array,@$desc);
    }
    return(\@array);
}

sub iodef_contacts {
    my $iodef = shift;
    
    my @array;
    foreach my $i (@{$iodef->get_Incident()}){
        my $c = $i->get_Contact();
        next unless($c);
        $c = [$c] unless(ref($c) eq 'ARRAY');
        push(@array,@$c);
    }
    return(\@array);
}

sub iodef_contacts_cc {
    my $i = shift;
    
    return unless($i->get_Contact());
    my $contacts = (ref($i->get_Contact()) eq 'ContactType') ? [$i->get_Contact()] : $i->get_Contact();
 
    my @array;
    foreach my $c (@$contacts){
        next unless($c->get_type() == ContactType::ContactRole::Contact_role_cc());
        push(@array,$c);
    }
    return unless(@array);
    return(\@array);
}
    
        

sub iodef_confidence {
    my $iodef = shift;
    
    if(ref($iodef) eq 'IODEFDocumentType'){
        $iodef = $iodef->get_Incident();
    }
    
    $iodef = [$iodef] unless(ref($iodef) eq 'ARRAY');
    
    my $ret = @{$iodef}[0]->get_Assessment();
    my @array;
    foreach my $a (@$ret){
        push(@array,$a->get_Confidence());
    }
    return(\@array);
}

sub iodef_assessments {
    my $iodef = shift;
    
    return [] unless(ref($iodef) eq 'IncidentType');
    return $iodef->get_Assessment();
}

sub iodef_impacts {
    my $iodef = shift;
    
    if(ref($iodef) eq 'IODEFDocumentType'){
        $iodef = $iodef->get_Incident();
    };
    $iodef = [$iodef] unless(ref($iodef) eq 'ARRAY');
    
    my $array;
    foreach my $i (@$iodef){
        my @local = @{$i->get_Assessment()};
        push(@$array, map { @{$_->get_Impact()} } @local);
    }
    return $array;
}

sub iodef_impacts_first {
    my $iodef = shift;

    return [] unless(ref($iodef) eq 'IncidentType');

    my $impacts = iodef_impacts($iodef);
    my $impact = @{$impacts}[0];
    return($impact);
}

sub iodef_address_type {
    my $type = shift;
    
    # TODO -- return contstant for net-addr-ipv4, etc.
    
    return $type;   
}

sub iodef_addresses {
    my $iodef   = shift;
    my $type    = shift;
    
    return unless($iodef);
    
    $type = iodef_address_type($type) if($type);
    
    if(ref($iodef) eq 'IODEFDocumentType'){
        $iodef = $iodef->get_Incident();
    }
    
    $iodef = [$iodef] unless(ref($iodef) eq 'ARRAY');
        
    my @array;
    foreach my $i (@$iodef){
        next unless($i->get_EventData());
        foreach my $e (@{$i->get_EventData()}){
            my @flows = (ref($e->get_Flow()) eq 'ARRAY') ? @{$e->get_Flow()} : $e->get_Flow();
            foreach my $f (@flows){
                my @systems = (ref($f->get_System()) eq 'ARRAY') ? @{$f->get_System()} : $f->get_System();
                foreach my $s (@systems){
                    my @nodes = (ref($s->get_Node()) eq 'ARRAY') ? @{$s->get_Node()} : $s->get_Node();
                    foreach my $n (@nodes){
                        my $addresses = $n->get_Address();
                        $addresses = [$addresses] if(ref($addresses) eq 'AddressType');
                        push(@array,@$addresses);
                    }
                }
            }
        }
    }
    return(\@array);
}

sub iodef_bgp {
    my $iodef   = shift;
    
    return unless($iodef);
    
    if(ref($iodef) eq 'IODEFDocumentType'){
        $iodef = $iodef->get_Incident();
    }
    
    $iodef = [$iodef] unless(ref($iodef) eq 'ARRAY');
        
    my @array;
    foreach my $i (@$iodef){
        next unless($i->get_EventData());
        foreach my $e (@{$i->get_EventData()}){
            my @flows = (ref($e->get_Flow()) eq 'ARRAY') ? @{$e->get_Flow()} : $e->get_Flow();
            foreach my $f (@flows){
                my @systems = (ref($f->get_System()) eq 'ARRAY') ? @{$f->get_System()} : $f->get_System();
                foreach my $s (@systems){
                    my $x = _additional_data($s);
                    next unless($x);
                    my $hash;
                    foreach (@$x){
                        next unless(lc($_->get_meaning()) =~ /^(asn|asn_desc|prefix|rir|cc)$/);
                        $hash->{$_->get_meaning()} = $_->get_content();
                    }
                    push(@array,$hash);
                }
            }
        }
    }
    return unless(@array);
    return(\@array);
}

sub iodef_systems {
    my $iodef = shift;
    
    my @array;
    return unless($iodef->get_EventData());
    foreach my $e (@{$iodef->get_EventData()}){
        my @flows = (ref($e->get_Flow()) eq 'ARRAY') ? @{$e->get_Flow()} : $e->get_Flow();
        foreach my $f (@flows){
            my @systems = (ref($f->get_System()) eq 'ARRAY') ? @{$f->get_System()} : $f->get_System();
            push(@array,@systems);
        }
    }
    return(\@array);
}

sub _additional_data {
    my $array = shift;
    
    $array = [$array] unless(ref($array) eq 'ARRAY'); 
    my $return_array;
    foreach my $e (@$array){
        next unless($e && $e->get_AdditionalData());
        my @additional_data = (ref($e->get_AdditionalData()) eq 'ARRAY') ? @{$e->get_AdditionalData()} : $e->get_AdditionalData();
        push(@$return_array,@additional_data);
    }
    return($return_array);
}     

sub iodef_additional_data {
    my $iodef = shift;

    if(ref($iodef) eq 'IODEFDocumentType'){
        $iodef = $iodef->get_Incident();
    }
    $iodef = [$iodef] unless(ref($iodef) eq 'ARRAY');
    
    my $array = _additional_data($iodef);
    return($array);
}

sub iodef_malware {
    my $iodef = shift;

    my $ad = iodef_additional_data($iodef);
    return unless($#{$ad});
    
    my $array = [];
    foreach (@$ad){
        next unless($_->get_meaning() =~ /^malware hash$/);
        push(@$array,$_);
    }
    return unless($#{$array} > -1);
    return $array;
}
    

sub iodef_events_additional_data {
    my $iodef = shift;
    
    my $array = [];
    foreach my $i (@{$iodef->get_Incident()}){
        next unless($i->get_EventData());
        if(my $ret = _additional_data($i->get_EventData())){
            push(@$array,@$ret);
        }
    }
    
    return($array);
}

sub iodef_systems_additional_data {
    my $iodef = shift;
    
    return unless(ref($iodef) eq 'IncidentType');
    
    my $array;
    foreach my $e (@{$iodef->get_EventData()}){
        my @flows = (ref($e->get_Flow()) eq 'ARRAY') ? @{$e->get_Flow()} : $e->get_Flow();
        foreach my $f (@flows){
            next unless($f->get_System());
            my @systems = (ref($f->get_System()) eq 'ARRAY') ? @{$f->get_System()} : $f->get_System();
            if(my $ret = _additional_data($f->get_System())){
                push(@$array,@$ret);
            }
        }
    }
    return($array);
}    

sub iodef_guid {
    my $iodef = shift;
    
    return unless(ref($iodef) eq 'IncidentType');
    
    my $ad = $iodef->get_AdditionalData();
    foreach (@$ad){
        next unless($_->get_meaning() =~ /^guid/);
        ## TODO -- return array of guids?
        return $_->get_content();
    }
}

sub iodef_uuid {
    my $iodef = shift;
    return $iodef->get_IncidentID->get_content();
}

sub new {
    my $class = shift;
    my $args = shift;

    $args->{'description'}  = 'unknown'     unless($args->{'description'});
    $args->{'lang'}         = 'EN'          unless($args->{'lang'});
    $args->{'timezone'}     = 'UTC'         unless($args->{'timezone'});

    unless(ref($args->{'description'}) eq 'MLStringType'){
        $args->{'description'} = MLStringType->new({
            lang    => $args->{'lang'},
            content => $args->{'description'},
        });
    }

    my $pb = IODEFDocumentType->new({
        lang        => $args->{'lang'},
        # IODEF version
        version     => '1.00',
        # PB version
        formatid    => '0.01',
        Incident    => [
            IncidentType->new({
                Description => $args->{'description'},
            }),
        ],
    });
    foreach(@plugins){
        $_->process($args,$pb);
    }

    return $pb;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Iodef::Pb::Simple - Perl extension providing high level API access to Iodef::Pb. It takes simple key-pair hashes and maps them to the appropriate IODEF classes using a Module::Pluggable framework of plugins.

=head1 SYNOPSIS

  use Iodef::Pb::Simple;
  use Data::Dumper;

  my $x = Iodef::Pb::Simple->new({
    contact     => 'Wes Young',
    #address    => 'example.com',
    #rdata      => '1.2.3.4',
    id          => '1234',
    address     => '1.1.1.1',
    prefix      => '1.1.1.0/24',
    asn         => 'AS1234',
    cc          => 'US',
    assessment  => 'botnet',
    confidence  => '50',
    restriction => 'private',
    method      => 'http://www.virustotal.com/analisis/02da4d701931b1b00703419a34313d41938e5bd22d336186e65ea1b8a6bfbf1d-1280410372',
  });

  my $str = $x->encode();
  warn Dumper($x);
  warn Dumper(IODEFDocumentType->decode($str));

=head1 DESCRIPTION

This library provides high level access to the Iodef::Pb API. It allows for the rapid generation of simple IODEF messages.

Once the buffer's are encoded, they can easily be transported via REST, ZeroMQ, Crossroads.io or any other messaging framework (or the google protocol RPC bits themselves). To store these in a database, you can easily base64 the data-structure and save as text.

=head2 EXPORT

None by default. Object Oriented.

=head1 SEE ALSO

 http://github.com/collectiveintel/iodef-pb-simple-perl
 http://github.com/collectiveintel/iodef-pb-perl
 https://github.com/collectiveintel/IODEF
 http://tools.ietf.org/html/rfc5070#section-3.2
 http://search.cpan.org/~gariev/Google-ProtocolBuffers/lib/Google/ProtocolBuffers.pm
 http://code.google.com/p/protobuf/
 http://search.cpan.org/~kasei/Class-Accessor/lib/Class/Accessor.pm
 http://search.cpan.org/~simonw/Module-Pluggable/lib/Module/Pluggable.pm
 http://collectiveintel.net

=head1 AUTHOR

Wes Young, E<lt>wes@barely3am.comE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2012 by Wes Young <claimid.com/wesyoung>
  Copyright (C) 2012 the REN-ISAC <ren-isac.net>
  Copyright (C) 2012 the trustee's of Indiana University <iu.edu>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
