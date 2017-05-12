/*=====================================================================

  File:      OlleComplexInteger.cs
  Summary:   A Format.Native UDT that represents a complex number
 
  This is an adaption of the original ComplexNumber sample that comes
  with SQL 2005. It's been changed to integer, to make a little easier
  to write test scripts for OlleDB.
---------------------------------------------------------------------
  This file is part of the Microsoft SQL Server Code Samples.
  Copyright (C) Microsoft Corporation.  All rights reserved.

  This source code is intended only as a supplement to Microsoft
  Development Tools and/or on-line documentation.  See these other
  materials for detailed information regarding Microsoft code samples.

  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
  KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
======================================================= */

using System;
using System.Data.Sql;
using System.Data.SqlTypes;
using System.Text.RegularExpressions;
using System.Runtime.InteropServices;
using System.Globalization;

[assembly: System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Design", "CA1020:AvoidNamespacesWithFewTypes", Scope = "namespace", Target = "Microsoft.Samples.SqlServer")]

namespace OlleDBtest
{
    [Serializable]
    [Microsoft.SqlServer.Server.SqlUserDefinedType(Microsoft.SqlServer.Server.Format.Native, IsByteOrdered = true)]
    public struct OlleComplexInteger : INullable, IComparable
    {
        //Regular expression used to parse values that are of the form (1,2i)
        private static readonly Regex _parser
            = new Regex(@"\A\(\s*(?<real>\-?\d+)\s*,\s*(?<img>\-?\d+(\.\d+)?)\s*i\s*\)",
            RegexOptions.Compiled | RegexOptions.ExplicitCapture);

        int _real;

        int _imaginary;

        bool _isnull;
        
        const string NULL = "<<null complex>>";

        static readonly OlleComplexInteger NULL_INSTANCE = new OlleComplexInteger(true);

        public OlleComplexInteger(int real, int imaginary)
        {
            this._real = real;
            this._imaginary = imaginary;
            this._isnull = false;
        }

        private OlleComplexInteger(bool isnull)
        {
            this._isnull = isnull;
            this._real = this._imaginary = 0;
        }

        public int Real
        {
            get
            {
                if (this._isnull)
                    throw new InvalidOperationException();

                return this._real;
            }
            set
            {
                this._real = value;
            }
        }

        public int Imaginary
        {
            get
            {
                if (this._isnull)
                    throw new InvalidOperationException();

                return this._imaginary;
            }
            set
            {
                this._imaginary = value;
            }
        }

        public double Modulus
        {
            get
            {
                if (this._isnull)
                    throw new InvalidOperationException();

                return Math.Sqrt(this._real * this._real
                    + this._imaginary * this._imaginary);
            }
        }

        #region value-based equality
        public int CompareTo(object obj)
        {
            if (!(obj is OlleComplexInteger))
                return -1;

            OlleComplexInteger c = (OlleComplexInteger)obj;

            if (this._isnull && c._isnull)
                return 0;

            if (this._isnull || c._isnull)
                return -1;

            if (this._real == c._real && this._imaginary == c._imaginary)
                return 0;

            if (Modulus == c.Modulus) // same modulus but different r/i, force diff
                return -1;

            // arbitrary comparison...semantics for complex numbers not necessarily correct
            return Modulus.CompareTo(c.Modulus);
        }

        public override bool Equals(object obj)
        {
            return this.CompareTo(obj) == 0;
        }

        public override int GetHashCode()
        {
            return Modulus.GetHashCode();
        }

        public static SqlBoolean operator ==(OlleComplexInteger c1, OlleComplexInteger c2)
        {
            return c1.Equals(c2);
        }

        public static SqlBoolean operator !=(OlleComplexInteger c1, OlleComplexInteger c2)
        {
            return !c1.Equals(c2);
        }

        public static SqlBoolean operator <(OlleComplexInteger c1, OlleComplexInteger c2)
        {
            return c1.CompareTo(c2) < 0;
        }

        public static SqlBoolean operator >(OlleComplexInteger c1, OlleComplexInteger c2)
        {
            return c1.CompareTo(c2) > 0;
        }

        public static OlleComplexInteger operator +(OlleComplexInteger c1, OlleComplexInteger c2)
        {
            OlleComplexInteger c3 = new OlleComplexInteger(false);
            c3._real = c1._real + c2._real;
            c3._imaginary = c1._imaginary + c2._imaginary;
            return c3;
        }

        public static OlleComplexInteger operator -(OlleComplexInteger c1, OlleComplexInteger c2)
        {
            OlleComplexInteger c3 = new OlleComplexInteger(false);
            c3._real = c1._real - c2._real;
            c3._imaginary = c1._imaginary - c2._imaginary;
            return c3;
        }


        #endregion

        public override string ToString()
        {
            return this._isnull ? NULL : ("("
                + this._real.ToString(CultureInfo.InvariantCulture) + ","
                + this._imaginary.ToString(CultureInfo.InvariantCulture)
                + "i)");
        }

        public bool IsNull
        {
            get
            {
                return this._isnull;
            }
        }

        public static OlleComplexInteger Parse(SqlString sqlString)
        {
            string value = sqlString.ToString();

            if (sqlString.IsNull)
                return new OlleComplexInteger(true);

            Match m = _parser.Match(value);

            if (!m.Success)
                throw new ArgumentException(
                    "Invalid format for complex number '" + value + "'. " 
                    + "Format is ( n, mi ) where n and m are floating point numbers");

            return new OlleComplexInteger(int.Parse(m.Groups[1].Value,
                CultureInfo.InvariantCulture), int.Parse(m.Groups[2].Value,
                CultureInfo.InvariantCulture));
        }

        public static OlleComplexInteger Null
        {
            get
            {
                return NULL_INSTANCE;
            }
        }
    }
}