/*
 *    Filename:  cppbfi.c++
 * Description:  A brainfuck interpreter
 *     Version:  1.0
 *     Created:  25/11/2010 21:24:01
 *    Revision:  27/11/2010 13:35:43
 *     License:  WTFPL => http://sam.zoy.org/wtfpl/COPYING
 */ 
#include <vector>
#include <stack>
#include <map>

#include <fstream>
#include <iostream>
#include <sstream>

int main(int argc, char* argv[])
{
    if(argc > 1)
    {
        std::vector<char> mem(30000, 0);    // Memory.
        unsigned int dp = 0;                // Data pointer
        std::ifstream script(argv[1]);      // Opens source file.

        if(script)
        {
            std::stringstream                    buff;
            std::string                          code;
            std::stack<unsigned int>             square_bracket;
            std::map<unsigned int, unsigned int> right2left;
            std::map<unsigned int, unsigned int> left2right;

            buff << script.rdbuf(); // Reads entire file.
            code = buff.str();      // Stores source code.
            script.close();
            for(unsigned int ip = 0; ip < code.size(); ip++)
            {
                if(code[ip] == '[')
                {
                    square_bracket.push(ip);
                }
                else if(code[ip] == ']')
                {
                    if(square_bracket.empty())
                    {
                        std::cerr << "Unmatched bracket\n";
                        return -1;
                    }
                    left2right[square_bracket.top()] = ip;
                    right2left[ip] = square_bracket.top();
                    square_bracket.pop();
                }
            }
            if(!square_bracket.empty())
            {
                std::cerr << "Unmatched bracket\n";
                return -1;
            }

            for(unsigned int ip = 0; ip < code.size(); ip++)
            {
                switch(code[ip])
                {
                    case '<':
                        --dp;
                        break;
                    case '>':
                        ++dp;
                        break;
                    case '+':
                        mem[dp]++;
                        break;
                    case '-':
                        mem[dp]--;
                        break;
                    case '.':
                        std::cout.put(mem[dp]);
                        break;
                    case ',':
                        std::cin.get(mem[dp]);
                        break;
                    case '[':
                        ip = (mem[dp] == 0) ? left2right[ip] : ip;
                        break;
                    case ']':
                        ip = right2left[ip] - 1;
                        break;
                    default:
                        break;
                }
            }
        }
    }
    else
    {
        std::cerr << "Usage:" << argv[0] << " script.bf\n";
    }

    return 0;
}
