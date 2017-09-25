namespace Random
{

  final class Xorshift
  {

    private uint64 m_iseed;

    uint64 seed
    {
      get const { return m_iseed; }
    }

    //Xorshift Functions

    uint nextInt(uint upper)
    {

      uint threshold = -upper % upper;

      while (true)
      {

        uint r =  nextInt();

        if (r >= threshold)
          return r % upper;

      }

      return upper;

    }

    uint32 nextInt()
    {

      /*

        Used this site to assist with this:
        http://excamera.com/sphinx/article-xorshift.html

        Might convert this into Xorshift* in the near future.

      */

    	m_iseed ^= m_iseed >> 12;
    	m_iseed ^= m_iseed << 25;
    	m_iseed ^= m_iseed >> 27;
    	return m_iseed;

    }

    double nextDouble()
    {

      return nextInt() * pow(2.0,-32.0);

    }

    //Xorshift Constructor
    Xorshift(uint64 in_seed)
    {

      m_iseed = in_seed;

    }

    //Default Constructor
    Xorshift()
    {

      m_iseed = UnixTimestamp();

    }

  }

  final class PCG
  {

    private uint64 m_iseed;

    uint64 seed
    {
      get const { return m_iseed; }
    }

    //PCG Functions

    uint nextInt(uint upper)
    {

      uint threshold = -upper % upper;

      while (true)
      {

        uint r =  nextInt();

        if (r >= threshold)
          return r % upper;

      }

      return upper;

    }


    uint nextInt()
    {
      uint64 oldstate = m_iseed;
      m_iseed = oldstate * uint64(6364136223846793005) + uint(0);
      uint xorshifted = ((oldstate >> uint(18)) ^ oldstate) >> uint(27);
      uint rot = oldstate >> uint(59);
      return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
    }

    double nextDouble()
    {

      return nextInt() * pow(2.0,-32.0);

    }

    //PCG Constructors

    PCG(uint64 in_seed)
    {

      m_iseed = in_seed;

    }

    //Default Constructor
    PCG()
    {

      m_iseed = UnixTimestamp();

    }

  }

  final class MersenneTwister
  {

    private uint64 m_iseed;
    private uint index = 313;
    private uint lower_mask = 0x7FFFFFFF;
    private uint upper_mask = ~lower_mask;
    private array<uint> MT(312);

    uint64 seed
    {
      get const { return m_iseed; }
    }

    //Mersenne Twister Functions

    uint nextInt(uint upper)
    {

      uint threshold = -upper % upper;

      while (true)
      {

        uint r =  nextInt();

        if (r >= threshold)
          return r % upper;

      }

      return upper;

    }


    uint nextInt()
    {

      if (index >= 312)
      {
         if (index > 312)
         {
           g_Log.PrintF("[Random] MersenneTwister Generator was never seeded!\n");
         }
         twist();
      }

      uint y = MT[index];
      y = y ^ ((y >> uint(29)) & uint(0x5555555555555555));
      y = y ^ ((y << uint(17)) & uint(0x71D67FFFEDA60000));
      y = y ^ ((y << uint(37)) & uint(0xFFF7EEE000000000));
      y = y ^ (y >> uint(43));

      ++index;

      return y;

    }

    double nextDouble()
    {

      return nextInt() * pow(2.0,-32.0);

    }

    void seed_mt(uint64 seed)
    {

      index = 312;
      MT[0] = seed;

      for (uint i = 1; i < 312; ++i)
      {
        MT[i] = (uint(6364136223846793005) * (MT[i - 1] ^ (MT[i - 1] >> (62))) + i);
      }

    }

    void twist()
    {

      for (uint i = 0; i < 312; ++i)
      {
        uint x = (MT[i] & upper_mask) + (MT[(i + 1) % 312] & lower_mask);
        uint xA = x >> 1;

        if (x % 2 != 0)
        {
          xA = xA ^ uint(0xB5026F5AA96619E9);
        }

        MT[i] = MT[(i + uint(156)) % 312] ^ xA;
      }

      index = 0;

    }

    //MersenneTwister Constructors

    MersenneTwister(uint64 in_seed)
    {

      m_iseed = in_seed;
      seed_mt(seed);

    }

    //Default Constructor
    MersenneTwister()
    {

      m_iseed = UnixTimestamp();
      seed_mt(m_iseed);

    }

  }
}
