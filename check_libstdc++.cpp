#include <boost/predef.h>

#if BOOST_LIB_STD_GNU
int main() {}
#else
#error libstdc++ not detected
#endif
