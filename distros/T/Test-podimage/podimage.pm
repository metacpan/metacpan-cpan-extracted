package Test::podimage;

our $VERSION = 0.06;

=pod

=head1 NAME

Test::podimage - Testing how CPAN and METACPAN display images in pod.

=head1 SYNOPSIS

local-dist image

=for html <img src="/test.png" title="img-tag, local-dist" alt="Inlineimage" />

remote image

=for html <img src="https://raw.githubusercontent.com/dk/Test-podimage/master/test.png" title="img-tag, local-dist" alt="Inlineimage" />

proposed tag C<=for image> local

=for image /test.png

proposed tag C<=for image> remote

=for image https://raw.githubusercontent.com/dk/Test-podimage/master/test.png

proposed tag C<=for text>

=for text TEXT SAMPLE

inline for 1:

=for html <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9gEEgIJDgjXTxYAAAE3SURBVGje7VhBDsMwCAPU/3+ZXbdKCRDMlLRwjJBqg4lpWFWVioOZqz9BQg+JxxC5bhKAaWAkWVVloGS1pXWEtKJSYfB19C2VqBQlqXetJDE7DxOxwCLIWGA9ZAQBMkPGW3Er7/m3VrTKK13xdsOT3z5yDJGoR6x4SnRdmeW/Q1reKmcc3tsVK0+yIBFrigXSQ1YyFQev/Zzp2FU5zNXD3z6yc3C/orS0mshcvkRUPiN/GMOW1nbx4+xKwFdAGvzNMeHuYqV+aTxDWlGpIKV4l0pUipLR+3AOUCRm5+EfKwMshIwF1kFGECBTZJwVt/Je8BwUrPJSVzS4Hk3y20eOIRL1iCVPia4rk/x3SMtb5ZTDe7ti5EkWJGRNscg4yEqm4tBdawTW2bGrdJirh799ZOPoV5Td4gPKYZdm2PperwAAAABJRU5ErkJggg==" title="img-tag, normal" alt="Inlineimage">

inline for @daxim:

=for html <p><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9gEEgIJDgjXTxYAAAE3SURBVGje7VhBDsMwCAPU/3+ZXbdKCRDMlLRwjJBqg4lpWFWVioOZqz9BQg+JxxC5bhKAaWAkWVVloGS1pXWEtKJSYfB19C2VqBQlqXetJDE7DxOxwCLIWGA9ZAQBMkPGW3Er7/m3VrTKK13xdsOT3z5yDJGoR6x4SnRdmeW/Q1reKmcc3tsVK0+yIBFrigXSQ1YyFQev/Zzp2FU5zNXD3z6yc3C/orS0mshcvkRUPiN/GMOW1nbx4+xKwFdAGvzNMeHuYqV+aTxDWlGpIKV4l0pUipLR+3AOUCRm5+EfKwMshIwF1kFGECBTZJwVt/Je8BwUrPJSVzS4Hk3y20eOIRL1iCVPia4rk/x3SMtb5ZTDe7ti5EkWJGRNscg4yEqm4tBdawTW2bGrdJirh799ZOPoV5Td4gPKYZdm2PperwAAAABJRU5ErkJggg==" title="img-tag, normal" alt="Inlineimage" /></p>

inline with wrapping and p:

=for html <p><img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgA
	AADIAAAAyCAYAAAAeP4ixAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2
	nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9gEEgIJDgjXTxYAAAE
	3SURBVGje7VhBDsMwCAPU/3+ZXbdKCRDMlLRwjJBqg4lpWFWVioOZqz9BQg+
	JxxC5bhKAaWAkWVVloGS1pXWEtKJSYfB19C2VqBQlqXetJDE7DxOxwCLIWGA
	9ZAQBMkPGW3Er7/m3VrTKK13xdsOT3z5yDJGoR6x4SnRdmeW/Q1reKmcc3ts
	VK0+yIBFrigXSQ1YyFQev/Zzp2FU5zNXD3z6yc3C/orS0mshcvkRUPiN/GMO
	W1nbx4+xKwFdAGvzNMeHuYqV+aTxDWlGpIKV4l0pUipLR+3AOUCRm5+EfKwM
	shIwF1kFGECBTZJwVt/Je8BwUrPJSVzS4Hk3y20eOIRL1iCVPia4rk/x3SMt
	b5ZTDe7ti5EkWJGRNscg4yEqm4tBdawTW2bGrdJirh799ZOPoV5Td4gPKYZ
	dm2PperwAAAABJRU5ErkJggg==" title="img-tag, normal" alt="Inlineimage" /></p>

begin/end:

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAY
AAAAeP4ixAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAA
CxMBAJqcGAAAAAd0SU1FB9gEEgIJDgjXTxYAAAE3SURBVGje7VhBDsMwCAPU/3+ZXbdKC
RDMlLRwjJBqg4lpWFWVioOZqz9BQg+JxxC5bhKAaWAkWVVloGS1pXWEtKJSYfB19C2VqB
QlqXetJDE7DxOxwCLIWGA9ZAQBMkPGW3Er7/m3VrTKK13xdsOT3z5yDJGoR6x4SnRdmeW
/Q1reKmcc3tsVK0+yIBFrigXSQ1YyFQev/Zzp2FU5zNXD3z6yc3C/orS0mshcvkRUPiN/
GMOW1nbx4+xKwFdAGvzNMeHuYqV+aTxDWlGpIKV4l0pUipLR+3AOUCRm5+EfKwMshIwF1
kFGECBTZJwVt/Je8BwUrPJSVzS4Hk3y20eOIRL1iCVPia4rk/x3SMtb5ZTDe7ti5EkWJG
RNscg4yEqm4tBdawTW2bGrdJirh799ZOPoV5Td4gPKYZdm2PperwAAAABJRU5ErkJggg=
=" title="img-tag, normal" alt="Inlineimage">

=end html

begin/end with p:

=begin html

<p>
<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAY
AAAAeP4ixAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAA
CxMBAJqcGAAAAAd0SU1FB9gEEgIJDgjXTxYAAAE3SURBVGje7VhBDsMwCAPU/3+ZXbdKC
RDMlLRwjJBqg4lpWFWVioOZqz9BQg+JxxC5bhKAaWAkWVVloGS1pXWEtKJSYfB19C2VqB
QlqXetJDE7DxOxwCLIWGA9ZAQBMkPGW3Er7/m3VrTKK13xdsOT3z5yDJGoR6x4SnRdmeW
/Q1reKmcc3tsVK0+yIBFrigXSQ1YyFQev/Zzp2FU5zNXD3z6yc3C/orS0mshcvkRUPiN/
GMOW1nbx4+xKwFdAGvzNMeHuYqV+aTxDWlGpIKV4l0pUipLR+3AOUCRm5+EfKwMshIwF1
kFGECBTZJwVt/Je8BwUrPJSVzS4Hk3y20eOIRL1iCVPia4rk/x3SMtb5ZTDe7ti5EkWJG
RNscg4yEqm4tBdawTW2bGrdJirh799ZOPoV5Td4gPKYZdm2PperwAAAABJRU5ErkJggg=
=" title="img-tag, normal" alt="Inlineimage" />
</p>

=end html

=cut

1;


