#!/usr/bin/perl

# Bibliotecas necessarias
use IO::Socket::INET;
use Sys::Hostname;
use Socket;
use Switch;


# Constantes de configuração
%IRC_SERVER_INFO = ();
$IRC_SERVER_INFO{IRC_SERVER}     = "irc.freenode.net";
$IRC_SERVER_INFO{IRC_PORT}       = 6667;

$IRC_SERVER_INFO{IRC_NICKNAME}   = "h4cker";
$IRC_SERVER_INFO{IRC_NICKPASS}   = "senhadonickh4cker";
$IRC_SERVER_INFO{IRC_NAME}       = "heloiza";
$IRC_SERVER_INFO{IRC_CHANNEL}    = "#hacknroll";

# Carrega os arquivos das mensagens
CarregaArquivos();


# Caso receba um Singal USR1 recarrega as mensagens. Isto serve para
# não ter que reiniciar o Bot quando for adicionar alguma nova frase
$SIG{USR1} = sub {
	print "Recarregando arquivos ...\n";
	CarregaArquivos();
};


print "Conectando em $IRC_SERVER_INFO{IRC_SERVER}:$IRC_SERVER_INFO{IRC_PORT} ...\n";
 
$estado = ST_CONECTANDO;
$s0ck = IO::Socket::INET->new
(
 			PeerAddr  => $IRC_SERVER_INFO{IRC_SERVER},   # host do server
			PeerPort  => $IRC_SERVER_INFO{IRC_PORT},     # porta em que o server está listening
            Timeout   => 60,                             # timeout de conexão
			Proto     => tcp
) || die ("Connection error!\n");

print "Conectado!\n";

print "Autenticando ...\n";

EnviaS0ck ("NICK $IRC_SERVER_INFO{IRC_NICKNAME}");
EnviaS0ck ("USER $IRC_SERVER_INFO{IRC_NICKNAME} $IRC_SERVER_INFO{IRC_NICKNAME} \"$IRC_SERVER_INFO{IRC_SERVER}\" : ($IRC_SERVER_INFO{IRC_NAME})");


while ($bufReceived = <$s0ck>)
{
	# remove todas as quebras de linha (chomp da uns pau louco)
	$bufReceived =~ s/[\r\n]//g;
	
	print "\[$bufReceived\]\n";
	
	if ($bufReceived =~ /NOTICE AUTH (.*)/)
	{
#		print "Autenticando ...\n";
		EnviaS0ck ("NICKSERV IDENTIFY $IRC_SERVER_INFO{IRC_NICKPASS}");
	}
	elsif ($bufReceived =~ /PING (.*)/)
	{
		EnviaS0ck ("PONG $1");
	}

	# Verifica as mensagens que são enviadas pelo servidor
	elsif ($bufReceived =~ /:(\S*) (\d+) (.*)/)
	{
		$cdMensagem = $2;
		
		print "Recebido codigo $cdMensagem ..\n";
		
		if ( $cdMensagem == "376" )
		{
			print "Autenticando .. \n";
			EnviaS0ck ("NICKSERV IDENTIFY $IRC_SERVER_INFO{IRC_NICKPASS}");
#			EnviaS0ck ("JOIN $IRC_SERVER_INFO{IRC_CHANNEL}");
#			sleep(3);
#			EnviaS0ck ("PRIVMSG $local :" . RandomMsg(@IRC_MSG_HELLO));
		}
		elsif ( ($cdMensagem == "451") or ($cdMensagem == "462") )
		{
			# Envia a senha de autenticacao e entrar no servidor
			EnviaS0ck ("NICKSERV IDENTIFY $IRC_SERVER_INFO{IRC_NICKPASS}");
		}
	}
	
	# Verifica as mensagens que são enviadas por um usuarios
	elsif ($bufReceived =~ /:(\w*)!(\S*) (.*)/)
	{
		# Separa os campos
		$nickname   = $1;
		$userwhois  = $1;
		$ircmessage = $3;
		
		print "$nickname -> $ircmessage\n";
		
		# Mensagens provindas do bot
		if ($nickname eq $IRC_SERVER_INFO{IRC_NICKNAME})
		{
			# Quando ele mudar de nick (pelo server ou pelo /NICK)
			if ($ircmessage =~ /NICK (.*)/)
			{
				EnviaS0ck ("NICK $IRC_SERVER_INFO{IRC_NICKNAME}");
				EnviaS0ck ("NICKSERV IDENTIFY $IRC_SERVER_INFO{IRC_NICKPASS}");
			}

			# Quando ele entrar em um canal
			elsif ($ircmessage =~ /JOIN (.*)/)
			{
				$local = $1;
				$msg = RandomMsg(@IRC_MSG_HELLO);
				sleep(3);
				EnviaS0ck ("PRIVMSG $local :$msg");
			}

		}
		else
		{
			# Quando algum usuario mudar de nick (isso ainda nao está funcionando 100%)
			if ($ircmessage =~ /NICK :(.*)/)
			{
				$novoNick = $1;
				#EnviaS0ck ("PRIVMSG $1 :$nickname superdigivolve paraaa .... $novoNick!!!");
			}
			
			# Mensagem de PART
			elsif (($ircmessage =~ /PART (\S*)/) || ($ircmessage =~ /QUIT (\S*)/))
			{
				$local = $1;
				
				$msg = RandomMsg(@IRC_MSG_PART);
				$msg =~ s/\(\(NICK\)\)/$nickname/ig;
				$msg =~ s/\(\(CHAN\)\)/$local/ig;
				
				sleep(3);
				EnviaS0ck ("PRIVMSG $local :$msg");
				
				print "$nickname saiu do canal $local.\n";
				
			}
			
			# Mensagem de JOIN
			elsif ($ircmessage =~ /JOIN (.*)/)
			{
				$local = $1;
				
				$msg = RandomMsg(@IRC_MSG_JOIN);
				$msg =~ s/\(\(NICK\)\)/$nickname/ig;
				$msg =~ s/\(\(CHAN\)\)/$local/ig;

				sleep(3);
				EnviaS0ck ("PRIVMSG $local :$msg");
				
				print "$nickname entrou no canal $local.\n";
			}

			# Mensagem de KICK
			elsif ($ircmessage =~ /KICK (\S*) (\S*) :(.*)/)
			{
				$local   = $1;
				$kicked  = $2;
				$msgkick = $3;
				
				# Se kikou o bot ele entra novamente no canal.
				if ($kicked =~ /$IRC_SERVER_INFO{IRC_NICKNAME}/)
				{
					print "Reentrando no canal $local .. \n";
					EnviaS0ck ("JOIN $local");
					sleep(3);
					EnviaS0ck ("PRIVMSG $local :Voltei! \\o/");
				}
				
				print "$kicked foi kikado do canal $local por $nickname\n";
				
			}
			
			elsif ($ircmessage =~ /MODE (\S*) (\S*) :(.*)/)
			{
				$local = $1;
				$modo  = $1;
				$nick  = $3;
				
				if ($nick =~ /$IRC_SERVER_INFO{IRC_NICKNAME}/)
				{
					if ($modo == '+v')
					{
						sleep(3);
						EnviaS0ck ("PRIVMSG $local :Obrigado pelo voice $nickname ;)");
					}
					elsif ($modo == '+o')
					{
						sleep(3);;
						EnviaS0ck ("PRIVMSG $local :$nickname: Uhuuuu. Hora de morfá!!! ;)");
					}
				}
			}
			
			# Mensagem enviadas para um local (#canal ou PVT)
			elsif ($ircmessage =~ /PRIVMSG (\S*) :(.*)/)
			{
				$local    = $1;
				$mensagem = $2;
				
				
				if ($local =~ /#(.*)/)
				{
					# Quando falar no canal, tenho que verificar se ele falou alguma coisa
					# com o bot ou que tenha o nick do bot. pra isso preciso limpar a mensagem
					$msgClean = RemoveIRCFormating($mensagem);
	
					if ($msgClean =~ /$IRC_SERVER_INFO{IRC_NICKNAME}/)
					{
						$msg = RandomMsg(@IRC_MSG_RESP);
						$msg =~ s/\(\(NICK\)\)/$nickname/ig;
						$msg =~ s/\(\(CHAN\)\)/$local/ig;

						sleep(3);
						EnviaS0ck ("PRIVMSG $local :$msg");
					}
	
				}
				else
				{
					print "$nickname disse '$mensagem' no PVT\n";
				}
				
				
			}
			# NOTICE menina :You are now identified for menina.]
			elsif ($ircmessage =~ /NOTICE (\S*) :(.*)/)
			{
				$nickname = $1;
				$message = $2;
				print "RECEBI O NOTICE!\n";
				if ($nickname eq $IRC_SERVER_INFO{IRC_NICKNAME})
				{
					if ($message =~ /You are now identified/)
					{
						print "Entrando no canal $IRC_SERVER_INFO{IRC_CHANNEL} .. \n";
						EnviaS0ck ("JOIN $IRC_SERVER_INFO{IRC_CHANNEL}");
					}
				}
			}
			else
			{
				print ">> $ircmessage\n";
			}
		}
	}
}


sub EnviaS0ck
{
	print "Enviando: " . @_[0] . "\n";
	print $s0ck @_[0] . "\n";
}

sub LoadFile
{
	open(FD, @_[0]) || die("Could not open file!");
	@raw_data=<FD>;
	close(FD);
	
	return @raw_data;
}

sub RandomMsg
{
	return $_[int rand($#_ + 1)];
}

sub RemoveIRCFormating
{
	$msg = @_[0];
	$msg =~ s/[\002\037\026\017]//ig;
	$msg =~ s/\003\d{1,2},\d{1,2}//ig;
	$msg =~ s/\003\d{1,2}//ig;
	$msg =~ s/\003//ig;
	return $msg;
}


sub CarregaArquivos {
	@IRC_MSG_JOIN = LoadFile("msgjoin.txt");
	print "[+] Carregado arquivo de join com " . @IRC_MSG_JOIN . " mensagems!\n"; 	
	
	@IRC_MSG_PART = LoadFile("msgpart.txt");
	print "[+] Carregado arquivo de part com " . @IRC_MSG_PART . " mensagems!\n";
	
	@IRC_MSG_RESP = LoadFile("msgresp.txt");
	print "[+] Carregado arquivo de respostas com " . @IRC_MSG_RESP . " mensagems!\n";
	
	@IRC_MSG_HELLO = LoadFile("msghello.txt");
	print "[+] Carregado arquivo de Hello com " . @IRC_MSG_HELLO . " mensagems!\n";
};

# TODO
# Malagueta -> MODE #Moqueca +o ZlotZ
# ZlotZ -> KICK #moqueca menina :concordo
