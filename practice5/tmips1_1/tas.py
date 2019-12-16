#! /usr/bin/env python

# Tiny Assembler for Tiny MIPS simulator
#  (Computer Architecture A)
#  Keiji Kimura, 2016
#
# Usage:
#    ./tas file.s
#
# The above generates the file named "file.dat" 
# containing machine instructsios for Tiny MIPS

from __future__ import print_function

import re
import sys

# Type of MIPS Instruction Kind
INSN_TYPE = 0
R_TYPE = 1
IA_TYPE = 2
IB_TYPE = 3
IM_TYPE = 4
J_TYPE = 5

# Instruction Information Table
InsnTab = {
	"add" : [R_TYPE, 0x20],
	"sub" : [R_TYPE, 0x22],
	"and" : [R_TYPE, 0x24],
	"or"  : [R_TYPE, 0x25],
	"nor" : [R_TYPE, 0x27],
	"slt" : [R_TYPE, 0x2a],
	"addi" : [IA_TYPE, 0x08],
	"andi" : [IA_TYPE, 0x0c],
	"ori" : [IA_TYPE, 0x0d],
	"lui" : [IA_TYPE, 0x0f],
	"beq" : [IB_TYPE, 0x04],
	"lw"  : [IM_TYPE, 0x23],
	"sw"  : [IM_TYPE, 0x2b],
	"j"   : [J_TYPE, 0x02]}

# Register Name Table
RegTab = {
	"zero" : 0,
	"at" : 1,
	"v0" : 2,  "v1" : 3,
	"a0" : 4,  "a1" : 5,  "a2" : 6,  "a3" : 7,
	"t0" : 8,  "t1" : 9,  "t2" : 10, "t3" : 11,
	"t4" : 12, "t5" : 13, "t6" : 14, "t7" : 15,
	"s0" : 16, "s1" : 17, "s2" : 18, "s3" : 19,
	"s4" : 20, "s5" : 21, "s6" : 22, "s7" : 23,
	"t8" : 24, "t9" : 25,
	"k0" : 26, "k1" : 27,
	"gp" : 28, "sp" : 29, "fp" : 30, "ra" : 31}

# Base class of a line of assembly file
class TasLine:
	def __init__(self, line, pc):
		self.line = line
		self.pc = pc
		self.fout = sys.stdout
		self.object = 0
		self.debug = False

	def set_fout(self, fout):
		self.fout = fout

	def set_debug(self, debug):
		self.debug = debug

	def next_pc(self):
		return self.pc+4

	def get_line(self):
		return self.line

	def get_pc(self):
		return self.pc

	def gen_code(self):
		return

	def out_object(self):
		print('%08x' %self.object, file=fout)

# Null line
class NulLine(TasLine):
	def __init__(self, line, pc):
		TasLine.__init__(self, line, pc)

	def next_pc(self):
		return self.pc

# types for get_imm
# given as "optype"
# default value is IMM_LO
IMM_LO = 0
IMM_HI = 1
IMM_ALL = 2

# get immediate and label value
def get_imm(imm, optype):
	retimm = 0
	if imm.find('hi(') == 0:
		optype = IMM_HI
		imm = re.sub('hi\(', '', imm)
		imm = re.sub('\).*$', '', imm)
	elif imm.find('lo(') == 0:
		optype = IMM_LO
		imm = re.sub('lo\(', '', imm)
		imm = re.sub('\).*$', '', imm)
	sign = 1
	if imm[0] == '-':
		sign = -1
		imm = imm.lstrip('-')
	if imm.isdigit():
		retimm = sign*int(imm)
	elif imm.find('0x') == 0:
		retimm = int(imm, 16) # currently ignore sign
	else:
		try:
			retimm = LabelTab[imm]
		except KeyError:
			print("Undefined Lable.", file=sys.stderr)
			sys.exit()
	if optype == IMM_LO:
		retimm = 0xffff & retimm
	elif optype == IMM_HI:
		retimm = retimm >> 16
	# else IMM_ALL
	return retimm

# Base class of a line of MIPS instructions
class InsnLine(TasLine):
	def __init__(self, line, pc, tokens, code):
		TasLine.__init__(self, line, pc)
		self.ope = tokens[0]
		self.op = tokens[1:4]
		self.code = code

	def get_reg(self, name):
		regname = name[1:]
		if regname.isdigit():
			regnum = int(regname)
		else:
			try:
				regnum = RegTab[regname]
			except KeyError:
				print("Invalid Register Name.", file=sys.stderr)
				sys.exit()
		return regnum

# R-Format Instructions
#  op Rd, Rs, Rt
class RLine(InsnLine):
	def __init__(self, line, pc, tokens, code):
		InsnLine.__init__(self, line, pc, tokens, code)

	def gen_code(self):
		for i in range(3):
			self.op[i] = self.get_reg(self.op[i])
				
		if self.debug:
			print('%x(%s), %d %d %d' % (self.code, self.ope,
						    self.op[0], self.op[1],
						    self.op[2]))
		self.object = (self.op[1] << 21) + (self.op[2] << 16) + (self.op[0] << 11) + self.code
		self.out_object()

# I-Format Instructions (Arithmetic and Logical)
#  op Rt, Rs, Imm
class IALine(InsnLine):
	def __init__(self, line, pc, tokens, code):
		InsnLine.__init__(self, line, pc, tokens, code)

	def gen_code(self):
		for i in range(2):
			self.op[i] = self.get_reg(self.op[i])
		self.op[2] = get_imm(self.op[2], IMM_LO)
		if self.debug:
			print('%x(%s), %d %d %d' % (self.code, self.ope,
						    self.op[0], self.op[1],
						    self.op[2]))
		self.object = (self.code << 26) + (self.op[1] << 21) + (self.op[0] << 16) + self.op[2]
		self.out_object()

# I-Format Instructions (Branch)
#  op Rs, Rt, BranchTarget
class IBLine(InsnLine):
	def __init__(self, line, pc, tokens, code):
		InsnLine.__init__(self, line, pc, tokens, code)

	def gen_code(self):
		for i in range(2):
			self.op[i] = self.get_reg(self.op[i])
		self.op[2] = (get_imm(self.op[2], IMM_ALL)-4-self.pc)>>2
		if self.debug:
			print('%x(%s), %d %d %d' % (self.code, self.ope,
						    self.op[0], self.op[1],
						    self.op[2]))
		self.object = (self.code << 26) + (self.op[0] << 21) + (self.op[1] << 16) + (0xffff & self.op[2])
		self.out_object()

# I-Format Instructions (Memory Access)
#  op Rt, Off(Rs)
class IMLine(InsnLine):
	def __init__(self, line, pc, tokens, code):
		InsnLine.__init__(self, line, pc, tokens, code)

	def gen_code(self):
		self.op[0] = self.get_reg(self.op[0])
		# exploit offset
		offset = re.sub('\(.*\)', '', self.op[1])
		sign = 1
		if offset[0] == '-':
			sign = -1
			offset = offset.lstrip('-')
		if offset.isdigit():
			self.op.append((0xffff & (sign*int(offset))))
		else:
			print("Invalid offset expression.", file=sys.stderr)
			sys.exit()
		# exploit register
		reg = re.sub('^.*\(', '', self.op[1])
		reg = re.sub('\).*$', '', reg)
		reg = reg.strip()
		self.op[1] = self.get_reg(reg)
		if self.debug:
			print('%x(%s), %d %d %d' % (self.code, self.ope,
						    self.op[0], self.op[1],
						    self.op[2]))
		self.object = (self.code << 26) + (self.op[1] << 21) + (self.op[0] << 16) + self.op[2]
		self.out_object()

# J-Format Instructions
#  op JumpTarget
class JLine(InsnLine):
	def __init__(self, line, pc, tokens, code):
		InsnLine.__init__(self, line, pc, tokens, code)

	def gen_code(self):
		self.op[0] = 0x03ffffff & (get_imm(self.op[0], IMM_ALL) >> 2)
		if self.debug:
			print('%x(%s), %x' % (self.code, self.ope, self.op[0]))
		self.object = (self.code << 26) + self.op[0]
		self.out_object()
		

# Basic class of Pseudo Instructions
class PLine(TasLine):
	def __init__(self, line, pc):
		TasLine.__init__(self, line, pc)

# DW
#  .dw data
class DWLine(PLine):
	def __init__(self, line, pc, data):
		PLine.__init__(self, line, pc)
		self.object = data

	def gen_code(self):
		self.out_object()

# Factory function for line objects
def  newInsnLine(line, pc, tokens):
	# check pseudo instructions
	if tokens[0] == '.org':
		adrs = get_imm(tokens[1], IMM_ALL)
		return NulLine(line, adrs)
	elif tokens[0] == '.dw':
		dwdata = get_imm(tokens[1], IMM_ALL)
		return DWLine(line, pc, dwdata)
	# check MIPS instructions
	insn_info = InsnTab[tokens[0]]
	if insn_info[0] == R_TYPE:
		return RLine(line, pc, tokens, insn_info[1])
	elif insn_info[0] == IA_TYPE:
		return IALine(line, pc, tokens, insn_info[1])
	elif insn_info[0] == IB_TYPE:
		return IBLine(line, pc, tokens, insn_info[1])
	elif insn_info[0] == IM_TYPE:
		return IMLine(line, pc, tokens, insn_info[1])
	elif insn_info[0] == J_TYPE:
		return JLine(line, pc, tokens, insn_info[1])
	else:
		return InsnLine(line, pc, tokens)

def  exploitLabel(line, pc):
	lmatch = re.match('^.*:', line)
	if lmatch:
		label = re.sub(':', '', lmatch.group())
		LabelTab[label] = pc
	return re.sub('^.*:\s*', '', line)

def  newTasLine(line, pc):
	nline = re.sub(';.*', '', line) # remove comment
	nline = re.sub(',', ' ', nline)  # remove comma
	nline = exploitLabel(nline, pc)
	if nline == '' :
		return NulLine(nline, pc)
	tokens = nline.split()
	rline = newInsnLine(nline, pc, tokens)
	return rline

# Initialization
LabelTab = {}
tas_pc = 0
insn_list = []

DEBUG = False
file_in = ''

# Processing command line arguments
for arg in sys.argv[1:]:
	if arg[0] == '-':
		if arg == '-debug':
			DEBUG = True
		else:
			print("Unkown command line option.", file=sys.stderr)
			sys.exit()
	else:
		file_in = arg

if len(file_in) == 0:
	print("Source file name is not specified.", file=sys.stderr)
	sys.exit()
if file_in.rfind('.s') == -1:
	print("Illegal suffix in the source file name.", file=sys.stderr)
	sys.exit()

file_out = file_in.replace('.s', '.dat')


try:
	fin = open(file_in)
	fout = open(file_out, 'w')
except IOError as e:
	print(file_in, ':', e.strerror, file=sys.stderr)
	sys.exit()

# Pass1: exploiting labels and storing instruction information
for line in fin:
	line = line.strip()
	# remove comments
	tas_line = newTasLine(line, tas_pc)
	tas_line.set_fout(fout)
	tas_line.set_debug(DEBUG)
	tas_pc = tas_line.next_pc()
	insn_list.append(tas_line)

if DEBUG:
	print(LabelTab)

# Pass2: generating code
for insn in insn_list:
	insn.gen_code()
	if DEBUG:
		print(insn.get_pc(), insn.get_line())
