require 'minitest/autorun'

class Compute
  def self.part1(ary)
    ary.map do |line|
      dd = line.split("\t").map(&:to_i)
      dd.max - dd.min
    end.reduce(&:+)
  end

  def self.part2(ary)
    ary.map do |line|
      dd = line.split("\t").map(&:to_i)
      res = nil
      dd[0..-2].each_with_index do |d, i|
        dd[i + 1..-1].each do |x|
          l, h = [d, x].sort
          if (h % l) == 0
            res = h / l
            break
          end
        end
        break if res
      end
      res
    end.reduce(&:+)
  end
end

class Tests < Minitest::Test
  def test_first
    assert_equal 18, Compute.part1(%W[5\t1\t9\t5 7\t5\t3 2\t4\t6\t8])
  end

  def test_second
    assert_equal 9, Compute.part2(%W[5\t9\t2\t8 9\t4\t7\t3 3\t8\t6\t5'])
  end
end
ary = %W[
  4168\t3925\t858\t2203\t440\t185\t2886\t160\t1811\t4272\t4333\t2180\t174\t157\t361\t1555
  150\t111\t188\t130\t98\t673\t408\t632\t771\t585\t191\t92\t622\t158\t537\t142
  5785\t5174\t1304\t3369\t3891\t131\t141\t5781\t5543\t4919\t478\t6585\t116\t520\t673\t112
  5900\t173\t5711\t236\t2920\t177\t3585\t4735\t2135\t2122\t5209\t265\t5889\t233\t4639\t5572
  861\t511\t907\t138\t981\t168\t889\t986\t980\t471\t107\t130\t596\t744\t251\t123
  2196\t188\t1245\t145\t1669\t2444\t656\t234\t1852\t610\t503\t2180\t551\t2241\t643\t175
  2051\t1518\t1744\t233\t2155\t139\t658\t159\t1178\t821\t167\t546\t126\t974\t136\t1946
  161\t1438\t3317\t4996\t4336\t2170\t130\t4987\t3323\t178\t174\t4830\t3737\t4611\t2655\t2743
  3990\t190\t192\t1630\t1623\t203\t1139\t2207\t3994\t1693\t1468\t1829\t164\t4391\t3867\t3036
  116\t1668\t1778\t69\t99\t761\t201\t2013\t837\t1225\t419\t120\t1920\t1950\t121\t1831
  107\t1006\t92\t807\t1880\t1420\t36\t1819\t1039\t1987\t114\t2028\t1771\t25\t85\t430
  5295\t1204\t242\t479\t273\t2868\t3453\t6095\t5324\t6047\t5143\t293\t3288\t3037\t184\t987
  295\t1988\t197\t2120\t199\t1856\t181\t232\t564\t1914\t1691\t210\t1527\t1731\t1575\t31
  191\t53\t714\t745\t89\t899\t854\t679\t45\t81\t726\t801\t72\t338\t95\t417
  219\t3933\t6626\t2137\t3222\t1637\t5312\t238\t5895\t222\t154\t6649\t169\t6438\t3435\t4183
  37\t1069\t166\t1037\t172\t258\t1071\t90\t497\t1219\t145\t1206\t143\t153\t1067\t510
]
puts format('Res1: %d', Compute.part1(ary))
puts format('Res2: %d', Compute.part2(ary))
