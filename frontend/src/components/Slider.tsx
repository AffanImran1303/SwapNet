import React, { useState } from 'react';

const ToggleSlider = () => {
  const [isActive, setIsActive] = useState(true); // true for Classic, false for P2P

  return (
    <div className="flex items-center justify-center">
      <div className="w-55 h-12 border border-bgSecondary border-opacity-50 rounded-full flex cursor-pointer">
        <span 
          className={`flex items-center justify-center px-3 py-1 rounded-full transition-all duration-300 ease-in-out ${
            isActive ? 'bg-bgSecondary text-white flex-grow' : 'text-purple-200 flex-none'
          }`}
          onClick={() => setIsActive(true)}
        >
          Classic
        </span>
        <span 
          className={`flex items-center justify-center px-3 py-1 rounded-full transition-all duration-300 ease-in-out ${
            !isActive ? 'bg-bgSecondary text-white flex-grow' : 'text-purple-200 flex-none'
          }`}
          onClick={() => setIsActive(false)}
        >
          P-2-P
        </span>
      </div>
    </div>
  );
};

export default ToggleSlider;
