# 路由服务配置 - BIRD路由守护进程
{
  pkgs,
  lib,
  config,
  ...
}:
let
  vars = import ./vars.nix { inherit pkgs lib; };
  coreVars = vars.coreRouter;
in
{
  services.bird = {
    enable = true;
    config = ''
      # 路由表定义
      ipv4 table master4;
      ipv6 table master6;

      # 内核路由协议 - 同步系统路由表
      protocol kernel {
        ipv4 {
          import all;
          export all;
        };
      }

      # 设备协议 - 监控网络接口状态
      protocol device {
      }

      # 静态路由协议 - 默认路由配置
      protocol static {
        ipv4 {
          export all;
        };
        # 上游默认路由
        route 0.0.0.0/0 via ${coreVars.networks.wan.upstream_gateway};
      }

      # OSPF协议 - 动态路由协议
      protocol ospf v2 ospf_core {
        ipv4 {
          import all;
          export all;
        };
        area ${toString coreVars.ospf.area} {
          interface "br-lan" {
            cost ${toString coreVars.ospf.cost};           # 最低成本，优先选择
            type broadcast;   # 广播网络类型
            hello ${toString coreVars.ospf.hello_interval};          # Hello间隔
            dead ${toString coreVars.ospf.dead_interval};          # 死亡检测
          };
        };
      }
    '';
  };
}
