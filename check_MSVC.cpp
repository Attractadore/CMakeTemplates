#include <boost/predef.h>

#if BOOST_COMP_MSVC
int main() {}
#else
#error MSVC STL not detected
#endif
