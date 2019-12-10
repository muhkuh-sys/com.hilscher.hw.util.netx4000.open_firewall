# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------#
#   Copyright (C) 2016 by Christoph Thelen                                #
#   doc_bacardi@users.sourceforge.net                                     #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
#-------------------------------------------------------------------------#


#----------------------------------------------------------------------------
#
# Set up the Muhkuh Build System.
#
SConscript('mbs/SConscript')
Import('atEnv')

# Create a build environment for the Cortex-R7 and Cortex-A9 based netX chips.
env_cortexR7 = atEnv.DEFAULT.CreateEnvironment(['gcc-arm-none-eabi-4.9', 'asciidoc'])
env_cortexR7.CreateCompilerEnv('NETX4000', ['arch=armv7', 'thumb'], ['arch=armv7-r', 'thumb'])


#----------------------------------------------------------------------------
#
# Create the compiler environments.
#
astrIncludePaths = ['src']

atEnv.NETX4000.Append(CPPPATH = astrIncludePaths)


#----------------------------------------------------------------------------
#
# Get the source code version from the VCS.
#
atEnv.DEFAULT.Version('#targets/version/version.h', 'templates/version.h')
atEnv.DEFAULT.Version('#targets/hboot_snippet.xml', 'templates/hboot_snippet.xml')


#----------------------------------------------------------------------------
#
# Build the platform libraries.
#
# Build the platform libraries.
SConscript('platform/SConscript')


#----------------------------------------------------------------------------
# This is the list of sources. The elements must be separated with whitespace
# (i.e. spaces, tabs, newlines). The amount of whitespace does not matter.
sources = """
  src/netx4000/cr7_open_netx4000_firewalls.S
"""


#----------------------------------------------------------------------------
global PROJECT_VERSION
#
# Build all files.
#
# netX4000 CR7 for LLRAM
# The list of include folders. Here it is used for all files.
astrIncludePaths = ['src', '#platform/src']

env_netx4000_cr7_llram = atEnv.NETX4000.Clone()
env_netx4000_cr7_llram.Append(CPPPATH = astrIncludePaths)
env_netx4000_cr7_llram.Replace(LDFILE = 'src/netx4000/intram.ld')
src_netx4000_cr7_llram = env_netx4000_cr7_llram.SetBuildPath('targets/netx4000_cr7_llram', 'src', sources)
elf_netx4000_cr7_llram = env_netx4000_cr7_llram.Elf('targets/netx4000_cr7_llram/open_firewall_netx4000.elf', src_netx4000_cr7_llram + env_netx4000_cr7_llram['PLATFORM_LIBRARY'])
txt_netx4000_cr7_llram = env_netx4000_cr7_llram.ObjDump('targets/netx4000_cr7_llram/open_firewall_netx4000.txt', elf_netx4000_cr7_llram, OBJDUMP_FLAGS=['--disassemble', '--source', '--all-headers', '--wide'])
bin_netx4000_cr7_llram = env_netx4000_cr7_llram.ObjCopy('targets/netx4000_cr7_llram/open_firewall_netx4000.bin', elf_netx4000_cr7_llram)

gccSymbols_netx4000_cr7_llram = env_netx4000_cr7_llram.GccSymbolTemplate('targets/netx4000_cr7_llram/snippet.xml', elf_netx4000_cr7_llram, GCCSYMBOLTEMPLATE_TEMPLATE='targets/hboot_snippet.xml',  GCCSYMBOLTEMPLATE_BINFILE=bin_netx4000_cr7_llram[0])
# Create the snippet from the parameters.
aArtifactGroupReverse4000 = ['com', 'hilscher', 'hw', 'util', 'netx4000']
atSnippet4000 = {
    'group': '.'.join(aArtifactGroupReverse4000),
    'artifact': 'open_firewall',
    'version': PROJECT_VERSION,
    'vcs_id': env_netx4000_cr7_llram.Version_GetVcsIdLong(),
    'vcs_url': env_netx4000_cr7_llram.Version_GetVcsUrl(),
    'license': 'GPL-2.0',
    'author_name': 'Muhkuh team',
    'author_url': 'https://github.com/muhkuh-sys',
    'description': 'open firewalls at netX4000.',
    'categories': ['netx4000', 'booting']
}
strArtifactPath4000 = 'targets/snippets/%s/%s/%s' % ('/'.join(aArtifactGroupReverse4000), atSnippet4000['artifact'], PROJECT_VERSION)
snippet_netx4000_com = env_netx4000_cr7_llram.HBootSnippet('%s/%s-%s.xml' % (strArtifactPath4000, atSnippet4000['artifact'], PROJECT_VERSION), gccSymbols_netx4000_cr7_llram, PARAMETER=atSnippet4000)

# Create the POM file.
tPOM4000 = env_netx4000_cr7_llram.POMTemplate('%s/%s-%s.pom' % (strArtifactPath4000, atSnippet4000['artifact'], PROJECT_VERSION), 'templates/pom.xml', POM_TEMPLATE_GROUP=atSnippet4000['group'], POM_TEMPLATE_ARTIFACT=atSnippet4000['artifact'], POM_TEMPLATE_VERSION=atSnippet4000['version'], POM_TEMPLATE_PACKAGING='xml')

# Create binaries for verification
hboot_netx4000_test02 = env_netx4000_cr7_llram.HBootImage('targets/verify/test02/test_snippet_netx4000_open_firewall.bin', 'verify/test02/test_snippet_netx4000_open_firewall.xml')