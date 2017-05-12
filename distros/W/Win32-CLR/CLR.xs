#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

using namespace System;

typedef Object^ Win32_CLR;
typedef Object^ CLR_Object;
typedef String^ CLR_String;
typedef array<Object^>^ CLR_Param1;
typedef array<Object^>^ CLR_Param2;
typedef array<Object^>^ CLR_Param3;
typedef array<Object^>^ CLR_Param4;
typedef array<Object^>^ CLR_Param5;

namespace XS {

    String^                     SvToString(SV* sv);
    array<Object^>^             SvToArray(SV* sv);
    Reflection::BindingFlags    GetBindingFlags(String^ member);
    Type^                       GetType(String^ name);
    void                        SvSetInstance(SV* sv, Object^ value);
    Object^                     SvGetInstance(SV* sv);
    void                        SvSetReturn(SV* sv, Object^ value);
    void                        SvSetString(SV* sv, String^ value);
    Object^                     InvokeOp(String^ name, Object^ left, Object^ right, bool reverse);
    Object^                     InvokeMember(Object^ target, String^ tname, String^ name, String^ option, array<Object^>^ params);

    ref class SvPointer {

    private:

        IntPtr _Pointer;

        !SvPointer();
        ~SvPointer();

    public:

        SvPointer(SV* sv);

        property SV* Pointer {
            SV* get() { return reinterpret_cast<SV*>( this->_Pointer.ToInt32() ); }
        }

        virtual String^ ToString() override;
        Object^ ChangeType(Type^ type_to);

    };

    SvPointer::SvPointer(SV* sv) {
        this->_Pointer = static_cast<IntPtr>( newSVsv(sv) );
    }

    SvPointer::!SvPointer() {}

    SvPointer::~SvPointer() {
        if (this->Pointer) { SvREFCNT_dec(this->Pointer); }
        this->!SvPointer();
    }

    String^ SvPointer::ToString() {
        return SvToString(this->Pointer);
    }

    Object^ SvPointer::ChangeType(Type^ type_to) {

        TypeCode code_to = Type::GetTypeCode(type_to);
        SV* sv = this->Pointer;

        switch (code_to) {
            case TypeCode::Boolean:
                return Convert::ToBoolean( SvTRUE(sv) );
            case TypeCode::SByte:
            case TypeCode::Int16:
            case TypeCode::Int32:
            case TypeCode::Int64:
                return Convert::ChangeType( safe_cast<Int32>( SvIV(sv) ), code_to );
            case TypeCode::Byte:
            case TypeCode::UInt16:
            case TypeCode::UInt32:
            case TypeCode::UInt64:
                return Convert::ChangeType( safe_cast<UInt32>( SvUV(sv) ), code_to );
            case TypeCode::Single:
            case TypeCode::Double:
                return Convert::ChangeType( safe_cast<Double>( SvNV(sv) ), code_to );
            case TypeCode::Decimal:
            case TypeCode::Char:
            case TypeCode::String:
                return Convert::ChangeType( SvToString(sv), code_to );
            default:
                return nullptr;
        }

    }

    ref class Binder: public Reflection::Binder {

    public:

        Binder() : Reflection::Binder() {}

    private:

       ref class StateHolder {

       public:
          array<Object^>^ Arguments;

       };

    public:

        virtual Reflection::FieldInfo^ BindToField(
            Reflection::BindingFlags        flags,
            array<Reflection::FieldInfo^>^  match,
            Object^                         value,
            Globalization::CultureInfo^     culture
        ) override
        {
            if (nullptr == match) {
                throw gcnew ArgumentNullException("match");
            }

            Reflection::FieldInfo^ matched = nullptr;

            for each(Reflection::FieldInfo^ field in match) {

                if (nullptr == value) {
                    matched = field;
                    break;
                }

                Type^ type_from = value->GetType();

                if (type_from == field->FieldType) { /* check exact match */
                    matched = field;
                    break;
                }

                if ( Convertible(type_from, field->FieldType) ) {
                    matched = field;
                }

            }

            return matched;
        }

        virtual Reflection::MethodBase^ BindToMethod(
            Reflection::BindingFlags                            flags,
            array<Reflection::MethodBase^>^                     match,
            array<Object^>^%                                    arguments,
            array<Reflection::ParameterModifier>^               modifiers,
            Globalization::CultureInfo^                         culture,
            array<String^>^                                     names,
            [Runtime::InteropServices::OutAttribute] Object^%   state
        ) override
        {
            StateHolder^ state_holder  = gcnew StateHolder();
            array<Object^>^ arguments_state = gcnew array<Object^>(arguments->Length);
            arguments->CopyTo(arguments_state, 0);
            state_holder->Arguments = arguments_state;
            state = state_holder;
            Reflection::MethodBase^ matched = nullptr;

            if (nullptr == match) {
                throw gcnew ArgumentNullException("match");
            }

            for each(Reflection::MethodBase^ method in match) {

                int exact = 0;
                int count = 0;
                array<Reflection::ParameterInfo^>^ parameters = method->GetParameters();

                if (arguments->Length != parameters->Length) {
                    continue;
                }

                for (int i = 0; i < arguments->Length; i++) {

                    if (nullptr != names) {

                        if (names->Length != arguments->Length) {
                            throw gcnew ArgumentException("names and arguments must have the same number of elements.");
                        }

                        for (int j = 0; j < names->Length; j++) {
                            if ( 0 == String::Compare(parameters[i]->Name, names[j]) ) {
                                arguments[i] = state_holder->Arguments[j];
                            }
                        }

                    }

                    if (nullptr == arguments[i]) {
                        exact++;
                        count++;
                        continue;
                    }

                    if ( arguments[i]->GetType() == parameters[i]->ParameterType ) {
                        exact++;
                    }

                    if ( Convertible( arguments[i]->GetType(), parameters[i]->ParameterType ) ) {
                        count++;
                    }
                    else {
                        break;
                    }

                }

                if (exact == arguments->Length) {
                    matched = method;
                    break;
                }

                if (count == arguments->Length) {
                    matched = method;
                }

            }

            return matched;
        }

        virtual Object^ ChangeType(Object^ value, Type^ type_to, Globalization::CultureInfo^ culture) override {

            if (nullptr == value) {
                return value;
            }

            Type^ type_from = value->GetType();

            if (type_from == type_to) {
                return value;
            }

            if ( Convertible(type_from, type_to) ) {

                if (SvPointer::typeid == type_from) {
                    return safe_cast<SvPointer^>(value)->ChangeType(type_to);
                }

                if (Object::typeid == type_to) {
                    return value;
                }

                return Convert::ChangeType(value, type_to, culture);

            }

            return nullptr;
        }

        virtual void ReorderArgumentArray(array<Object^>^% arguments, Object^ state_holder) override {
            safe_cast<StateHolder^>(state_holder)->Arguments->CopyTo(arguments, 0);
        }

        virtual Reflection::MethodBase^ SelectMethod(
            Reflection::BindingFlags                flags,
            array<Reflection::MethodBase^>^         match,
            array<Type^>^                           types,
            array<Reflection::ParameterModifier>^   modifiers
        ) override
        {

            Reflection::MethodBase^ matched = nullptr;

            if (nullptr == match) {
                throw gcnew ArgumentNullException("match");
            }

            for each(Reflection::MethodBase^ method in match) {

                int exact = 0;
                int count = 0;
                array<Reflection::ParameterInfo^>^ parameters = method->GetParameters();

                if (types->Length != parameters->Length) {
                    continue;
                }

                for (int i = 0; i < types->Length; i++) {

                    if ( types[i] == parameters[i]->ParameterType ) {
                        exact++;
                    }

                    if ( Convertible(types[i], parameters[i]->ParameterType) ) {
                        count++;
                    }
                    else {
                        break;
                    }

                }

                if (exact == types->Length) {
                    matched = method;
                    break;
                }

                if (count == types->Length) {
                    matched = method;
                }

            }

            return matched;
        }

        virtual Reflection::PropertyInfo^ SelectProperty(
            Reflection::BindingFlags                flags,
            array<Reflection::PropertyInfo^>^       match,
            Type^                                   return_type,
            array<Type^>^                           indexes,
            array<Reflection::ParameterModifier>^   modifiers
        ) override
        {

            Reflection::PropertyInfo^ matched = nullptr;

            if (nullptr == match) {
                throw gcnew ArgumentNullException("match");
            }

            for each(Reflection::PropertyInfo^ prop in match) {

                int exact = 0;
                int count = 0;
                array<Reflection::ParameterInfo^>^ parameters = prop->GetIndexParameters();

                if (indexes->Length != parameters->Length) {
                    continue;
                }

                for (int i = 0; i < indexes->Length; i++) {

                    if ( indexes[i] == parameters[i]->ParameterType ) {
                        exact++;
                    }

                    if ( Convertible(indexes[i], parameters[i]->ParameterType) ) {
                        count++;
                    }
                    else {
                        break;
                    }

                }

                if (exact == indexes->Length && return_type == prop->PropertyType) {
                    matched = prop;
                    break;
                }

                if ( count == indexes->Length && Convertible(return_type, prop->PropertyType) ) {
                    matched = prop;
                }

            }

            return matched;
        }

    private:

        bool Convertible(Type^ type_from, Type^ type_to) {

            if (type_from == type_to) {
                return true;
            }

            if (Object::typeid == type_to) {
                return true;
            }

            if (String::typeid == type_from && type_to->IsPrimitive) {
                return true;
            }

            if (String::typeid == type_to) {
                return true;
            }

            if (SvPointer::typeid == type_from) {

                TypeCode code_to = Type::GetTypeCode(type_to);

                switch (code_to) {
                    case TypeCode::Boolean:
                    case TypeCode::SByte:
                    case TypeCode::Int16:
                    case TypeCode::Int32:
                    case TypeCode::Int64:
                    case TypeCode::Byte:
                    case TypeCode::UInt16:
                    case TypeCode::UInt32:
                    case TypeCode::UInt64:
                    case TypeCode::Single:
                    case TypeCode::Double:
                    case TypeCode::Decimal:
                    case TypeCode::Char:
                    case TypeCode::String:
                        return true;
                    default:
                        return false;
                }

            }

            if (Decimal::typeid == type_from) {

                TypeCode code_to = Type::GetTypeCode(type_to);

                switch (code_to) {
                    case TypeCode::Boolean:
                    case TypeCode::SByte:
                    case TypeCode::Int16:
                    case TypeCode::Int32:
                    case TypeCode::Int64:
                    case TypeCode::Byte:
                    case TypeCode::UInt16:
                    case TypeCode::UInt32:
                    case TypeCode::UInt64:
                    case TypeCode::Single:
                    case TypeCode::Double:
                    case TypeCode::String:
                        return true;
                    default:
                        return false;
                }

            }

            if (Decimal::typeid == type_to) {

                TypeCode code_from = Type::GetTypeCode(type_from);

                switch (code_from) {
                    case TypeCode::Boolean:
                    case TypeCode::SByte:
                    case TypeCode::Int16:
                    case TypeCode::Int32:
                    case TypeCode::Int64:
                    case TypeCode::Byte:
                    case TypeCode::UInt16:
                    case TypeCode::UInt32:
                    case TypeCode::UInt64:
                    case TypeCode::Single:
                    case TypeCode::Double:
                    case TypeCode::String:
                        return true;
                    default:
                        return false;
                }

            }

            if (type_from->IsPrimitive && type_to->IsPrimitive) {

                TypeCode code_from = Type::GetTypeCode(type_from);
                TypeCode code_to   = Type::GetTypeCode(type_to);

                if (code_from == code_to) {
                    return true;
                }

                if (code_from == TypeCode::SByte) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::Int16:
                        case TypeCode::Int32:
                        case TypeCode::Int64:
                        case TypeCode::Byte:
                        case TypeCode::UInt16:
                        case TypeCode::UInt32:
                        case TypeCode::UInt64:
                        case TypeCode::Single:
                        case TypeCode::Double:
                        case TypeCode::Char:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::Int16) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::SByte:
                        case TypeCode::Int32:
                        case TypeCode::Int64:
                        case TypeCode::Byte:
                        case TypeCode::UInt16:
                        case TypeCode::UInt32:
                        case TypeCode::UInt64:
                        case TypeCode::Single:
                        case TypeCode::Double:
                        case TypeCode::Char:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::Int32) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::SByte:
                        case TypeCode::Int16:
                        case TypeCode::Int64:
                        case TypeCode::Byte:
                        case TypeCode::UInt16:
                        case TypeCode::UInt32:
                        case TypeCode::UInt64:
                        case TypeCode::Single:
                        case TypeCode::Double:
                        case TypeCode::Char:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::Int64) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::SByte:
                        case TypeCode::Int16:
                        case TypeCode::Int32:
                        case TypeCode::Byte:
                        case TypeCode::UInt16:
                        case TypeCode::UInt32:
                        case TypeCode::UInt64:
                        case TypeCode::Single:
                        case TypeCode::Double:
                        case TypeCode::Char:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::Byte) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::SByte:
                        case TypeCode::Int16:
                        case TypeCode::Int32:
                        case TypeCode::Int64:
                        case TypeCode::UInt16:
                        case TypeCode::UInt32:
                        case TypeCode::UInt64:
                        case TypeCode::Single:
                        case TypeCode::Double:
                        case TypeCode::Char:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::UInt16) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::SByte:
                        case TypeCode::Int16:
                        case TypeCode::Int32:
                        case TypeCode::Int64:
                        case TypeCode::Byte:
                        case TypeCode::UInt32:
                        case TypeCode::UInt64:
                        case TypeCode::Single:
                        case TypeCode::Double:
                        case TypeCode::Char:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::UInt32) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::SByte:
                        case TypeCode::Int16:
                        case TypeCode::Int32:
                        case TypeCode::Int64:
                        case TypeCode::Byte:
                        case TypeCode::UInt16:
                        case TypeCode::UInt64:
                        case TypeCode::Single:
                        case TypeCode::Double:
                        case TypeCode::Char:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::UInt64) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::SByte:
                        case TypeCode::Int16:
                        case TypeCode::Int32:
                        case TypeCode::Int64:
                        case TypeCode::Byte:
                        case TypeCode::UInt16:
                        case TypeCode::UInt32:
                        case TypeCode::Single:
                        case TypeCode::Double:
                        case TypeCode::Char:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::Single) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::SByte:
                        case TypeCode::Int16:
                        case TypeCode::Int32:
                        case TypeCode::Int64:
                        case TypeCode::Byte:
                        case TypeCode::UInt16:
                        case TypeCode::UInt32:
                        case TypeCode::UInt64:
                        case TypeCode::Single:
                        case TypeCode::Double:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::Double) {
                    switch (code_to) {
                        case TypeCode::Boolean:
                        case TypeCode::SByte:
                        case TypeCode::Int16:
                        case TypeCode::Int32:
                        case TypeCode::Int64:
                        case TypeCode::Byte:
                        case TypeCode::UInt16:
                        case TypeCode::UInt32:
                        case TypeCode::UInt64:
                        case TypeCode::Single:
                            return true;
                        default:
                            return false;
                    }
                }

                if (code_from == TypeCode::Char) {
                    switch (code_to) {
                        case TypeCode::Byte:
                        case TypeCode::Int16:
                        case TypeCode::Int32:
                        case TypeCode::Int64:
                        case TypeCode::SByte:
                        case TypeCode::UInt16:
                        case TypeCode::UInt32:
                        case TypeCode::UInt64:
                            return true;
                        default:
                            return false;
                    }
                }

            }

            return false;

        }

    };

    ref class Assembly {

        static Assembly();
        static Collections::Generic::List<Reflection::Assembly^>^ AsmCache;
        static Collections::Generic::Dictionary<String^, Type^>^  TypeCache;

    public:

        static void Add(Reflection::Assembly^ assembly);
        static void Add(Type^ type);
        static Reflection::Assembly^ Load(String^ name);
        static Reflection::Assembly^ LoadFrom(String^ filename);
        static Type^ GetType(String^ tname);

    };

    ref class Code {

        IntPtr _Pointer;
        Type^ ReturnType;

        !Code();
        ~Code();

    public:

        Code(SV* code, Type^ type);

        property SV* Pointer {
            SV* get() { return reinterpret_cast<SV*>( this->_Pointer.ToInt32() ); }
        }

        Object^ Call(... array<Object^>^ params);
        Delegate^ CreateDelegate(Type^ deleg_type);

    };

    void SvSetString(SV* sv, String^ value) {

        Text::UTF8Encoding^ utf8_enc;
        array<Byte>^ utf8_bytes;
        utf8_enc   = gcnew Text::UTF8Encoding();
        utf8_bytes = utf8_enc->GetBytes( value->ToString() );

        if (0 < utf8_bytes->Length) {
            pin_ptr<Byte> utf8_ptr = &utf8_bytes[0];
            sv_setpvn( sv, reinterpret_cast<char*>(utf8_ptr), utf8_bytes->Length );
        }
        else {
            sv_setpv(sv, "");
        }

        SvUTF8_on(sv);
    }

    String^ SvToString(SV* sv) {
        if ( !SvOK(sv) ) {
            return nullptr;
        }
        else if ( SvUTF8(sv) ) {
            Text::UTF8Encoding^ utf8_enc = gcnew Text::UTF8Encoding();
            return gcnew String( SvPV_nolen(sv), 0, SvCUR(sv), utf8_enc );
        }
        else {
            IntPtr pv_ptr = static_cast<IntPtr>( SvPV_nolen(sv) );
            return Runtime::InteropServices::Marshal::PtrToStringAnsi(pv_ptr);
        }
    }

    array<Object^>^ SvToArray(SV* sv) {

        AV* av = reinterpret_cast<AV*>( SvRV(sv) );
        int length = av_len(av) + 1;
        array<Object^>^ arr = gcnew array<Object^>(length);

        for (int i = 0; i < length; i++) {
            SV** value = av_fetch(av, i, FALSE);
            arr[i] = SvGetInstance(*value);
        }

        return arr;
    }

    Reflection::BindingFlags GetBindingFlags(String^ member) {
        return static_cast<Reflection::BindingFlags>(
            Enum::Parse(Reflection::BindingFlags::typeid, member)
        );
    }

    Object^ SvGetInstance(SV* sv) {

        if ( !SvOK(sv) ) {
            return nullptr;
        }

        if ( sv_isobject(sv) && sv_derived_from(sv, "Win32::CLR") ) {
            Runtime::InteropServices::GCHandle gch;
            int addr = SvIV( reinterpret_cast<SV*>( SvRV(sv) ) );
            IntPtr ptr = static_cast<IntPtr>(addr);
            gch = Runtime::InteropServices::GCHandle::FromIntPtr(ptr);
            return gch.Target;
        }

        if ( SvROK(sv) && SvTYPE( SvRV(sv) ) == SVt_PVAV ) {
            return SvToArray(sv);
        }

        /*
        if (&PL_sv_undef == sv) {
            return nullptr;
        }
        */

        return gcnew SvPointer(sv);
    }

    void SvSetInstance(SV* sv, Object^ value) {
        Runtime::InteropServices::GCHandle gch;
        gch = Runtime::InteropServices::GCHandle::Alloc(value);
        int addr = Runtime::InteropServices::GCHandle::ToIntPtr(gch).ToInt32();
        sv_setref_iv(sv, "Win32::CLR", addr);
    }

    void SvSetReturn(SV* sv, Object^ value) {

        if (nullptr == value) {
            SvSetSV(sv, &PL_sv_undef);
            return;
        }

        Type^ type_from = value->GetType();
        TypeCode code_from = Type::GetTypeCode(type_from);

        if (SvPointer::typeid == type_from) {
            SvSetSV( sv, safe_cast<SvPointer^>(value)->Pointer );
            return;
        }

        switch(code_from) {
            case TypeCode::Boolean:
                SvSetSV( sv, boolSV( safe_cast<Boolean>(value) ) );
                break;
            case TypeCode::SByte:
            case TypeCode::Int16:
            case TypeCode::Int32:
            case TypeCode::Int64:
                sv_setiv( sv, Convert::ToInt32(value) );
                break;
            case TypeCode::Byte:
            case TypeCode::UInt16:
            case TypeCode::UInt32:
            case TypeCode::UInt64:
                sv_setuv( sv, Convert::ToUInt32(value) );
                break;
            case TypeCode::Single:
            case TypeCode::Double:
                sv_setnv( sv, Convert::ToDouble(value) );
                break;
            case TypeCode::Decimal:
            case TypeCode::Char:
            case TypeCode::String:
                SvSetString( sv, value->ToString() );
                break;
            default:
                SvSetInstance(sv, value);
        }

    }

    Type^ GetType(String^ tname) {
        Type^ type = Type::GetType(tname);
        if (nullptr == type) {
            type = Assembly::GetType(tname);
        }
        return type;
    }

    static Assembly::Assembly() {
        AsmCache  = gcnew Collections::Generic::List<Reflection::Assembly^>();
        TypeCache = gcnew Collections::Generic::Dictionary<String^, Type^>();
    }

    void Assembly::Add(Reflection::Assembly^ assembly) {
        if ( !AsmCache->Contains(assembly) ) {
            AsmCache->Add(assembly);
        }
    }

    void Assembly::Add(Type^ type) {
        TypeCache->Add(type->FullName, type);
        TypeCache->Add(type->AssemblyQualifiedName, type);
    }

    Reflection::Assembly^ Assembly::Load(String^ name) {
        Reflection::Assembly^ assembly;
        assembly = Reflection::Assembly::Load(name);
        Add(assembly);
        return assembly;
    }

    Reflection::Assembly^ Assembly::LoadFrom(String^ filename) {
        Reflection::Assembly^ assembly;
        assembly = Reflection::Assembly::LoadFrom(filename);
        Add(assembly);
        return assembly;
    }

    Type^ Assembly::GetType(String^ tname) {

        Type^ type;

        if ( TypeCache->TryGetValue(tname, type) ) {
            return type;
        }

        for each(Reflection::Assembly^ assembly in AsmCache) {
            type = assembly->GetType(tname);
            if (nullptr != type) {
                Add(type);
                return type;
            }
        }

        return nullptr;
    }

    Code::Code(SV* code, Type^ type) {
        this->_Pointer   = static_cast<IntPtr>( newSVsv(code) );
        this->ReturnType = type;
    }

    Code::!Code() {}
    Code::~Code() {
        if (this->Pointer) { SvREFCNT_dec(this->Pointer); }
        this->!Code();
    }

    Object^ Code::Call(... array<Object^>^ params) {

        int count;
        Object^ retval;

        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);

        for each(Object^ value in params) {
            SV* mortal = sv_newmortal();
            SvSetReturn(mortal, value);
            XPUSHs(mortal);
        }

        PUTBACK;

        count = call_sv(this->Pointer, G_SCALAR);

        SPAGAIN;

        if ( 0 < count && Void::typeid != this->ReturnType ) {

            retval = SvGetInstance(POPs);

            if (nullptr != retval) {
                if ( SvPointer::typeid == retval->GetType() ) {
                    retval = safe_cast<SvPointer^>(retval)->ChangeType(this->ReturnType);
                }
            }

        }
        else {
            retval = nullptr;
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }

    Delegate^ Code::CreateDelegate(Type^ deleg_type) {

        Reflection::MethodInfo^             method_info;
        array<Reflection::ParameterInfo^>^  param_info;
        array<Type^>^                       param_types;

        Reflection::Emit::DynamicMethod^    dyn_method;
        Reflection::Emit::ILGenerator^      dyn_method_il;
        Reflection::Emit::LocalBuilder^     deleg_param;

        method_info = deleg_type->GetMethod("Invoke");
        param_info  = method_info->GetParameters();

        param_types    = gcnew array<Type^>(param_info->Length + 1);
        param_types[0] = Code::typeid;

        for (int i = 0; i < param_info->Length; i++) {
            param_types[i + 1] = param_info[i]->ParameterType;
        }

        dyn_method = gcnew Reflection::Emit::DynamicMethod(
            "", /* method name (anonymous) */
            method_info->ReturnType,
            param_types,
            Code::typeid
        );

        dyn_method_il = dyn_method->GetILGenerator(256);
        deleg_param   = dyn_method_il->DeclareLocal( Type::GetType("System.Object[]") );

        dyn_method_il->Emit(Reflection::Emit::OpCodes::Ldc_I4, param_types->Length);
        dyn_method_il->Emit(Reflection::Emit::OpCodes::Newarr, Object::typeid);
        dyn_method_il->Emit(Reflection::Emit::OpCodes::Stloc, deleg_param);

        for (int i = 1; i < param_types->Length; i++) {
            dyn_method_il->Emit(Reflection::Emit::OpCodes::Ldloc, deleg_param);
            dyn_method_il->Emit(Reflection::Emit::OpCodes::Ldc_I4, i - 1);
            dyn_method_il->Emit(Reflection::Emit::OpCodes::Ldarg_S, i);
            dyn_method_il->Emit(Reflection::Emit::OpCodes::Stelem_Ref);
        }

        dyn_method_il->Emit(Reflection::Emit::OpCodes::Ldarg_0); /* load this pointer */
        dyn_method_il->Emit(Reflection::Emit::OpCodes::Ldloc, deleg_param);

        dyn_method_il->Emit( Reflection::Emit::OpCodes::Call, Code::typeid->GetMethod("Call") );

        if (method_info->ReturnType == Void::typeid) {
            dyn_method_il->Emit(Reflection::Emit::OpCodes::Pop);
        }
        else {
            dyn_method_il->Emit(Reflection::Emit::OpCodes::Castclass, method_info->ReturnType);
        }

        dyn_method_il->Emit(Reflection::Emit::OpCodes::Ret);
        return dyn_method->CreateDelegate(deleg_type, this);
    }

    Object^ InvokeMember(Object^ target, String^ tname, String^ name, String^ option, array<Object^>^ params) {
        Reflection::BindingFlags flags;
        Type^ type = XS::GetType(tname);
        String^ target_type = nullptr == target ? ", Static" : ", Instance";
        flags = GetBindingFlags("Public, IgnoreCase, FlattenHierarchy, " + option + target_type);
        return type->InvokeMember(name, flags, gcnew XS::Binder(), target, params);
    }

    Object^ InvokeOp(String^ name, Object^ left, Object^ right, bool reverse) {
        Reflection::BindingFlags flags;
        array<Object^>^ params = reverse ? gcnew array<Object^>{right, left} : gcnew array<Object^>{left, right};
        flags = GetBindingFlags("Public, FlattenHierarchy, InvokeMethod, Static, Instance");
        return params[0]->GetType()->InvokeMember(name, flags, gcnew XS::Binder(), nullptr, params);
    }

}

MODULE = Win32::CLR    PACKAGE = Win32::CLR

CLR_Object
_create_instance(Win32_CLR self, CLR_String tname, CLR_Param2 params = nullptr, ...)
CODE:
    try {
        RETVAL = XS::InvokeMember(self, tname, "", "CreateInstance, Instance", params);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

void
DESTROY(SV* sv)
CODE:
    int addr = SvIV( reinterpret_cast<SV*>( SvRV(sv) ) );
    IntPtr ptr = static_cast<IntPtr>(addr);
    Runtime::InteropServices::GCHandle gch = Runtime::InteropServices::GCHandle::FromIntPtr(ptr);
    gch.Free();

CLR_Object
_call_method(Win32_CLR self, CLR_String tname, CLR_String name, CLR_Param3 params = nullptr, ...)
CODE:
    try {
        RETVAL = XS::InvokeMember(self, tname, name, "InvokeMethod, OptionalParamBinding", params);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

CLR_Object
_call_generic_method(Win32_CLR self, CLR_String tname, CLR_String name, AV* generic_tnames, CLR_Param4 params = nullptr, ...)
PREINIT:
    Reflection::MethodInfo^ info;
    Reflection::BindingFlags flags;
CODE:
    try {
        Type^ type = XS::GetType(tname);
        String^ call_type = nullptr == self ? "Static" : "Instance";
        flags = XS::GetBindingFlags("Public, FlattenHierarchy, InvokeMethod, OptionalParamBinding, " + call_type);
        int length = av_len(generic_tnames) + 1;
        array<Type^>^ generic_types = gcnew array<Type^>(length);
        for (int i = 0; i < length; i++) {
            SV** generic_tname = av_fetch(generic_tnames, i, FALSE);
            generic_types[i] = XS::GetType( XS::SvToString(*generic_tname) );
        }
        info   = type->GetMethod(name, flags)->GetGenericMethodDefinition()->MakeGenericMethod(generic_types);
        RETVAL = info->Invoke(self, flags, gcnew XS::Binder(), params, nullptr);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

CLR_Object
_get_field(Win32_CLR self, CLR_String tname, CLR_String name, CLR_Param3 params = nullptr, ...)
CODE:
    try {
        RETVAL = XS::InvokeMember(self, tname, name, "GetField", params);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

void
_set_field(Win32_CLR self, CLR_String tname, CLR_String name, CLR_Param3 params = nullptr, ...)
CODE:
    try {
        XS::InvokeMember(self, tname, name, "SetField", params);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }

CLR_Object
_get_property(Win32_CLR self, CLR_String tname, CLR_String name, CLR_Param3 params = nullptr, ...)
CODE:
    try {
        RETVAL = XS::InvokeMember(self, tname, name, "GetProperty", params);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

void
_set_property(Win32_CLR self, CLR_String tname, CLR_String name, CLR_Param3 params = nullptr, ...)
CODE:
    try {
        XS::InvokeMember(self, tname, name, "SetProperty", params);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }

CLR_Object
_get_value(Win32_CLR self, CLR_String tname, CLR_String name, CLR_Param3 params = nullptr, ...)
CODE:
    try {
        RETVAL = XS::InvokeMember(self, tname, name, "GetProperty, GetField", params);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

void
_set_value(Win32_CLR self, CLR_String tname, CLR_String name, CLR_Param3 params = nullptr, ...)
CODE:
    try {
        XS::InvokeMember(self, tname, name, "SetProperty, SetField", params);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }

bool
_derived_from(Win32_CLR self, CLR_String tname)
CODE:
    bool found = false;
    Type^ find_type = XS::GetType(tname);
    for (Type^ type = self->GetType(); type != nullptr; type = type->BaseType) {
        if (type == find_type) {
            found = true;
            break;
        }
    }
    RETVAL = found;
OUTPUT:
    RETVAL

CLR_Object
load(SV* package, CLR_String name)
CODE:
    try {
        RETVAL = XS::Assembly::Load(name);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

CLR_Object
load_from(SV* package, CLR_String filename)
CODE:
    try {
        RETVAL = XS::Assembly::LoadFrom(filename);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

CLR_Object
_create_delegate(SV* package, CLR_String tname, SV* sv)
CODE:
    try {
        Type^ deleg_type = XS::GetType(tname);
        Type^ return_type = deleg_type->GetMethod("Invoke")->ReturnType;
        XS::Code^ code = gcnew XS::Code(sv, return_type);
        RETVAL = code->CreateDelegate(deleg_type);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

void
_add_event(Win32_CLR self, CLR_String tname, CLR_String name, CLR_Object handler)
PREINIT:
    Delegate^ deleg;
CODE:
    try {
        Type^ type = XS::GetType(tname);
        Reflection::EventInfo^ info = type->GetEvent(name);
        if ( XS::SvPointer::typeid == handler->GetType() ) {
            Type^ deleg_type = info->EventHandlerType;
            Type^ return_type = deleg_type->GetMethod("Invoke")->ReturnType;
            XS::Code^ code = gcnew XS::Code( safe_cast<XS::SvPointer^>(handler)->Pointer, return_type );
            deleg = code->CreateDelegate(deleg_type);
        }
        else {
            deleg = safe_cast<Delegate^>(handler);
        }
        info->AddEventHandler(self, deleg);
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }

void
_remove_event(Win32_CLR self, CLR_String tname, CLR_String name, CLR_Object handler)
CODE: 
    try {
        Type^ type = XS::GetType(tname);
        Reflection::EventInfo^ info = type->GetEvent(name);
        info->RemoveEventHandler(self, safe_cast<Delegate^>(handler) );
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }

CLR_Object
_create_array(Win32_CLR self, CLR_String tname, ...)
CODE:
    try {
        Type^ type = XS::GetType(tname);
        Array^ arr = Array::CreateInstance(type, items - 2);
        for (int i = 0; i < arr->Length; i++) {
            Object^ value = XS::SvGetInstance( ST(i + 2) );
            if (nullptr != value) {
                if ( XS::SvPointer::typeid == value->GetType() ) {
                    value = safe_cast<XS::SvPointer^>(value)->ChangeType(type);
                }
            }
            arr->SetValue(value, i);
        }
        RETVAL = arr;
    }
    catch (Exception^ ex) {
        SV* err;
        err = get_sv("@", TRUE);
        XS::SvSetInstance(err, ex);
        croak(NULL);
    }
OUTPUT:
    RETVAL

int
get_type_hash(Win32_CLR self, CLR_String tname = nullptr)
CODE:
    Type^ type = (nullptr == self ? XS::GetType(tname) : self->GetType() );
    if (nullptr == type) {
        XSRETURN_UNDEF;
    }
    else {
        RETVAL = type->GetHashCode();
    }
OUTPUT:
    RETVAL

CLR_String
get_qualified_type(Win32_CLR self, CLR_String tname = nullptr)
CODE:
    Type^ type = (nullptr == self ? XS::GetType(tname) : self->GetType() );
    if (nullptr == type) {
        XSRETURN_UNDEF;
    }
    else {
        RETVAL = type->AssemblyQualifiedName;
    }
OUTPUT:
    RETVAL

CLR_String
get_type_name(Win32_CLR self, CLR_String tname = nullptr)
CODE:
    Type^ type = ( nullptr == self ? XS::GetType(tname) : self->GetType() );
    if (nullptr == type) {
        XSRETURN_UNDEF;
    }
    else {
        RETVAL = type->FullName;
    }
OUTPUT:
    RETVAL

int
get_addr(SV* self)
CODE:
    RETVAL = safe_cast<int>( SvIV( reinterpret_cast<SV*>( SvRV(self) ) ) );
OUTPUT:
    RETVAL

bool
_has_member( Win32_CLR self, CLR_String tname, CLR_String name, CLR_String member_type = gcnew String("Method, Field, Property, Event") )
PREINIT:
    Reflection::MemberTypes member_flags;
    Reflection::BindingFlags binding_flags;
    array<Reflection::MemberInfo^>^ info;
CODE:
    Type^ type = XS::GetType(tname);
    member_flags = static_cast<Reflection::MemberTypes>(
        Enum::Parse(Reflection::MemberTypes::typeid, member_type)
    );
    binding_flags = XS::GetBindingFlags("Public, IgnoreCase, FlattenHierarchy, Static, Instance");
    info = type->GetMember(name, member_flags, binding_flags);
    RETVAL = (0 < info->Length);
OUTPUT:
    RETVAL

CLR_Object
_create_enum(Win32_CLR self, CLR_String tname, CLR_String value)
CODE:
    Type^ type = XS::GetType(tname);
    RETVAL = Enum::Parse(type, value);
OUTPUT:
    RETVAL

CLR_String
to_string(Win32_CLR self, ...)
CODE:
    RETVAL = self->ToString();
OUTPUT:
    RETVAL

bool
op_boolify(Win32_CLR self, ...)
CODE:
    /* RETVAL = Convert::ToBoolean(self); */
    RETVAL = true;
OUTPUT:
    RETVAL

bool
op_equality(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    Object^ equal = XS::InvokeOp("op_Equality", self, right, reverse);
    if (nullptr == equal) {
        equal = XS::InvokeOp("Equals", self, right, reverse);
    }

    if (nullptr != equal) {
        RETVAL = safe_cast<Boolean>(equal);
    }
    else {
        XSRETURN_NO;
    }
OUTPUT:
    RETVAL

bool
op_inequality(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    Object^ equal = XS::InvokeOp("op_Inequality", self, right, reverse);
    if (nullptr == equal) {
        equal = XS::InvokeOp("op_Equality", self, right, reverse);
        if (nullptr == equal) {
            equal = XS::InvokeOp("Equals", self, right, reverse);
            if (nullptr == equal) {
                XSRETURN_YES;
            }
            else {
                RETVAL = !safe_cast<Boolean>(equal);
            }
        }
        else {
            RETVAL = !safe_cast<Boolean>(equal);
        }
    }
    else {
        RETVAL = safe_cast<Boolean>(equal);
    }
OUTPUT:
    RETVAL

CLR_Object
op_addition(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeOp("op_Addition", self, right, reverse);
    if (nullptr == RETVAL) {
        warn("Warning: Operator \"+\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_subtraction(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeOp("op_Subtraction", self, right, reverse);
    if (nullptr == RETVAL) {
        warn("Warning: Operator \"-\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_multiply(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeOp("op_Multiply", self, right, reverse);
    if (nullptr == RETVAL) {
        warn("Warning: Operator \"*\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_division(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeOp("op_Division", self, right, reverse);
    if (nullptr == RETVAL) {
        warn("Warning: Operator \"/\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_modulus(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeOp("op_Modulus", self, right, reverse);
    if (nullptr == RETVAL) {
        warn("Warning: Operator \"%\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_greaterthan(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeOp("op_GreaterThan", self, right, reverse);
    if (nullptr == RETVAL) {
        warn("Warning: Operator \">\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_greaterthan_or_equal(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeOp("op_GreaterThanOrEqual", self, right, reverse);
    if (nullptr == RETVAL) {
        warn("Warning: Operator \">=\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_lessthan(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeOp("op_LessThan", self, right, reverse);
    if (nullptr == RETVAL) {
        warn("Warning: Operator \"<\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_lessthan_or_equal(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeOp("op_LessThanOrEqual", self, right, reverse);
    if (nullptr == RETVAL) {
        warn("Warning: Operator \"<=\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_increment(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeMember(
        nullptr,
        self->GetType()->AssemblyQualifiedName,
        "op_Increment",
        "InvokeMethod, OptionalParamBinding, Static",
        gcnew array<Object^>{self}
    );
    if (nullptr == RETVAL) {
        warn("Warning: Operator \"++\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

CLR_Object
op_decrement(Win32_CLR self, CLR_Object right, bool reverse)
CODE:
    RETVAL = XS::InvokeMember(
        nullptr,
        self->GetType()->AssemblyQualifiedName,
        "op_Decrement",
        "InvokeMethod, OptionalParamBinding, Static",
        gcnew array<Object^>{self}
    );
    if (nullptr == RETVAL) {
        warn("Warning: Operator \"--\" not found");
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL
