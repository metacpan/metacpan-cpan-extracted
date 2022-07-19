/*
MIT License

Copyright (c) 2019 SergeyBel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// the AES library has been modified to reduce heap memory allocation

#pragma once

#ifndef _AES_H_
#define _AES_H_

#include <cstring>
#include <iostream>
#include <stdio.h>

using namespace std;

class AES256
{
private:
    const int Nb = 4;
    const int Nk = 8;
    const int Nr = 14;

    const unsigned int blockBytesLen = 4 * Nb * sizeof(unsigned char);

    void SubBytes(unsigned char** state);

    void ShiftRow(unsigned char** state, int i, int n);    // shift row i on n positions

    void ShiftRows(unsigned char** state);

    unsigned char xtime(unsigned char b);    // multiply on x

    unsigned char mul_bytes(unsigned char a, unsigned char b);

    void MixSingleColumn(unsigned char *r);

    void MixColumns(unsigned char** state);

    void AddRoundKey(unsigned char** state, unsigned char* key);

    void SubWord(unsigned char* a);

    void RotWord(unsigned char* a);

    void XorWords(unsigned char* a, unsigned char* b, unsigned char* c);

    void Rcon(unsigned char* a, int n);

    void InvSubBytes(unsigned char** state);

    void InvMixColumns(unsigned char** state);

    void InvShiftRows(unsigned char** state);

    void KeyExpansion(const unsigned char* key, unsigned char w[]);

    void EncryptBlock(const unsigned char* in, unsigned char out[], unsigned char* key);
    void DecryptBlock(const unsigned char* in, unsigned char out[], unsigned char* key);

    void XorBlocks(const unsigned char* a, const unsigned char* b, unsigned char* c, unsigned int len);

public:
    AES256();

    unsigned int GetPaddingLength(unsigned int len);

	int EncryptCBC(const unsigned char* in, unsigned int inLen, const unsigned char* key, const unsigned char* iv, unsigned char* out);
    int DecryptCBC(const unsigned char* in, unsigned int inLen, const unsigned char* key, const unsigned char* iv, unsigned char* out);

    void printHexArray(unsigned char a[], unsigned int n);
};

#endif
