// Dummy App
// $ g++ dummyApp.cpp -o dummyApp && ./dummyApp

#include <stdio.h> // printf
#include <unistd.h> // usleep
#include <iostream> // cout

using namespace std;

// 1000 == 1s
// 500 == 0.5s
// 100 == 0.1s
const int NUM_MILLI_SECONDS = 1;

int main()
{
    // printf("\ncount every %d milliseconds\n", NUM_MILLI_SECONDS);
    
    long long int count = 0;
    
    while (true) {
        count++;
        cout << "\r" << "\033[1;31m" << count << "\033[0m" << std::flush; // print on same line // red
        usleep(1000*NUM_MILLI_SECONDS);
    }
    return 0;
}
