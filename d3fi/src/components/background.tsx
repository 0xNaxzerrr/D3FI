export default function Background() {
  return (
    <>
      {/* Background Elements */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#0A0A0A] via-[#0F0F0F] to-[#0A0A0A]"></div>
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_120%,rgba(255,138,101,0.1),rgba(255,138,101,0))]"></div>
      <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-[0.02]"></div>

      {/* Glow Effects */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-[#FF8A65] rounded-full mix-blend-screen opacity-[0.03] blur-3xl"></div>
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-[#FF8A65] rounded-full mix-blend-screen opacity-[0.03] blur-3xl"></div>

      {/* Dots Pattern */}
      <div className="absolute top-[10%] left-[10%] w-2 h-2 bg-[#FF8A65] rounded-full opacity-40"></div>
      <div className="absolute top-[15%] left-[20%] w-1.5 h-1.5 bg-[#FF8A65] rounded-full opacity-30"></div>
      <div className="absolute top-[25%] left-[15%] w-2.5 h-2.5 bg-[#FF8A65] rounded-full opacity-50"></div>
      <div className="absolute top-[35%] left-[25%] w-1 h-1 bg-[#FF8A65] rounded-full opacity-40"></div>
      <div className="absolute top-[45%] left-[18%] w-2 h-2 bg-[#FF8A65] rounded-full opacity-30"></div>
      
      <div className="absolute top-[20%] right-[15%] w-2 h-2 bg-[#FF8A65] rounded-full opacity-40"></div>
      <div className="absolute top-[30%] right-[25%] w-1.5 h-1.5 bg-[#FF8A65] rounded-full opacity-30"></div>
      <div className="absolute top-[40%] right-[18%] w-2.5 h-2.5 bg-[#FF8A65] rounded-full opacity-50"></div>
      <div className="absolute top-[50%] right-[22%] w-1 h-1 bg-[#FF8A65] rounded-full opacity-40"></div>
      <div className="absolute top-[60%] right-[15%] w-2 h-2 bg-[#FF8A65] rounded-full opacity-30"></div>

      <div className="absolute bottom-[15%] left-[20%] w-2 h-2 bg-[#FF8A65] rounded-full opacity-40"></div>
      <div className="absolute bottom-[25%] left-[15%] w-1.5 h-1.5 bg-[#FF8A65] rounded-full opacity-30"></div>
      <div className="absolute bottom-[35%] left-[25%] w-2.5 h-2.5 bg-[#FF8A65] rounded-full opacity-50"></div>
      <div className="absolute bottom-[45%] left-[18%] w-1 h-1 bg-[#FF8A65] rounded-full opacity-40"></div>
      <div className="absolute bottom-[55%] left-[22%] w-2 h-2 bg-[#FF8A65] rounded-full opacity-30"></div>

      <div className="absolute bottom-[20%] right-[15%] w-2 h-2 bg-[#FF8A65] rounded-full opacity-40"></div>
      <div className="absolute bottom-[30%] right-[25%] w-1.5 h-1.5 bg-[#FF8A65] rounded-full opacity-30"></div>
      <div className="absolute bottom-[40%] right-[18%] w-2.5 h-2.5 bg-[#FF8A65] rounded-full opacity-50"></div>
      <div className="absolute bottom-[50%] right-[22%] w-1 h-1 bg-[#FF8A65] rounded-full opacity-40"></div>
      <div className="absolute bottom-[60%] right-[15%] w-2 h-2 bg-[#FF8A65] rounded-full opacity-30"></div>
    </>
  );
}
