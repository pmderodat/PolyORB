CXXOBJS          = \
		Ada_Corba_Exceptions.o \
		Ada_Corba_Orb.o \
		Ada_Corba_Boa.o \
		Ada_exceptions.o \
		Ada_Giop_c.o \
		Ada_Giop_s.o \
		Ada_Iop.o \
		Ada_memBufferedStream.o \
		Ada_netBufferedStream.o \
		Ada_OmniObject.o \
		Ada_OmniRopeAndKey.o \
		omniObject_C2Ada.o \
		proxyObjectFactory_C2Ada.o \
		omniObject_C2Ada.o \
		proxyObjectFactory_C2Ada.o  

CXXSRCS       =   \
		Ada_Corba_Exceptions.cc \
		Ada_Corba_Orb.cc \
		Ada_Corba_Boa.cc \
		Ada_exceptions.cc \
		Ada_Giop_c.cc \
		Ada_Giop_s.cc \
		Ada_Iop.cc \
		Ada_memBufferedStream.cc \
		Ada_netBufferedStream.cc \
		Ada_OmniObject.cc \
		Ada_OmniRopeAndKey.cc \
		omniObject_C2Ada.cc \
		proxyObjectFactory_C2Ada.cc \
		omniObject_C2Ada.cc \
		proxyObjectFactory_C2Ada.cc


DIR_CPPFLAGS = -I. -I../omniORB_2.7.0/include
DIR_CPPFLAGS += $(CORBA_CPPFLAGS) 

lib = $(patsubst %,$(LibPattern),adabroker)

all:: previous_check $(lib) adaobjs


$(lib): $(CXXOBJS)
	@$(StaticLinkLibrary)

clean::
	rm *.ali *.o Ada_Sys_Dep sys_dep.ads *~ libadabroker.a


previous_check: Ada_Sys_Dep
	./Ada_Sys_Dep

Ada_Sys_Dep: Ada_Sys_Dep.cc
	$(CXX) $(DIR_CPPFLAGS) Ada_Sys_Dep.cc -o Ada_Sys_Dep 


adaobjs: sys_dep.ads
	gnatmake -gnata -m -i adabroker.ads


sys_dep.ads : sys_dep_before_preprocessor.ads
	gnatprep sys_dep_before_preprocessor.ads sys_dep.ads \
$(ADABROKER_BOOLEANTYPE_DIR)/$(platform)

